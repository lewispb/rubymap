import { Map, Popup, NavigationControl, GeolocateControl, setWorkerUrl } from "maplibre-gl"
import { currentTheme, onThemeChange } from "theme"

// MapLibre loads its worker relative to its own URL, which does not work with
// digested asset paths, so point it at the pinned worker module instead.
setWorkerUrl(import.meta.resolve("maplibre-gl-worker"))

const STYLES = {
  light: "https://tiles.openfreemap.org/styles/positron",
  dark: "https://tiles.openfreemap.org/styles/dark"
}

const TYPE_LABELS = { business: "Company", meetup: "Meetup", event: "Event" }
const CLUSTER_MAX_ZOOM = 12

const app = document.querySelector(".app")
const panel = document.getElementById("panel")
const list = document.getElementById("places")
const listHeading = document.getElementById("list-heading")
const emptyMessage = document.getElementById("places-empty")
const search = document.getElementById("search")
const filters = document.getElementById("filters")
const inView = document.getElementById("in-view")
const panelToggle = document.getElementById("panel-toggle")

let features = []
let popup = null
let selectedId = null

const map = new Map({
  container: "map",
  style: STYLES[currentTheme()],
  center: [-2.58791, 51.454514],
  zoom: 2,
  hash: "view",
  attributionControl: { compact: true }
})

// The panel covers the left of the map on wide screens and the top on phones,
// so centre the map in the area it leaves visible.
const wideScreen = matchMedia("(min-width: 721px)")

function fitPadding() {
  if (panel.classList.contains("is-expanded")) return

  const bounds = panel.getBoundingClientRect()
  const padding = wideScreen.matches ? { left: Math.round(bounds.right), top: 0, right: 0, bottom: 0 } : { left: 0, top: Math.round(bounds.bottom), right: 0, bottom: 0 }
  const current = map.getPadding()

  // Setting the padding stops any camera animation, so only set it when it changes.
  if (padding.left !== current.left || padding.top !== current.top) map.setPadding(padding)
}

fitPadding()
new ResizeObserver(fitPadding).observe(panel)

map.addControl(new NavigationControl({ visualizePitch: true }), "bottom-right")
map.addControl(new GeolocateControl({ positionOptions: { enableHighAccuracy: false }, fitBoundsOptions: { maxZoom: 10 } }), "bottom-right")

document.documentElement.dataset.mapTheme = currentTheme()

onThemeChange((theme) => {
  document.documentElement.dataset.mapTheme = theme
  map.setStyle(STYLES[theme], { diff: false })
})

map.on("style.load", () => {
  map.setProjection({ type: "globe" })
  addPlaces()
})

fetch(app.dataset.locationsUrl, { headers: { Accept: "application/geo+json, application/json" } })
  .then((response) => response.json())
  .then((collection) => {
    features = collection.features
    renderCounts()
    update()
  })

// Map layers

function addPlaces() {
  const colors = readColors()

  map.addSource("places", {
    type: "geojson",
    data: featureCollection(visibleFeatures()),
    cluster: true,
    clusterMaxZoom: CLUSTER_MAX_ZOOM,
    clusterRadius: 44
  })

  map.addLayer({
    id: "clusters",
    type: "circle",
    source: "places",
    filter: ["has", "point_count"],
    paint: {
      "circle-color": colors.accent,
      "circle-opacity": 0.92,
      "circle-radius": ["step", ["get", "point_count"], 14, 5, 18, 15, 23, 40, 28],
      "circle-stroke-width": 3,
      "circle-stroke-color": colors.accent,
      "circle-stroke-opacity": 0.28
    }
  })

  map.addLayer({
    id: "cluster-count",
    type: "symbol",
    source: "places",
    filter: ["has", "point_count"],
    layout: {
      "text-field": ["get", "point_count_abbreviated"],
      "text-font": ["Noto Sans Bold"],
      "text-size": 13,
      "text-allow-overlap": true
    },
    paint: { "text-color": colors.accentInk }
  })

  map.addLayer({
    id: "place",
    type: "circle",
    source: "places",
    filter: ["!", ["has", "point_count"]],
    paint: {
      "circle-color": ["match", ["get", "type"], "meetup", colors.meetup, "event", colors.event, colors.business],
      "circle-radius": ["interpolate", ["linear"], ["zoom"], 2, 5, 12, 8],
      "circle-stroke-width": 2,
      "circle-stroke-color": colors.stroke
    }
  })
}

function readColors() {
  const style = getComputedStyle(document.documentElement)
  const value = (name) => style.getPropertyValue(name).trim()

  return {
    accent: value("--accent"),
    accentInk: value("--accent-ink"),
    business: value("--type-business"),
    meetup: value("--type-meetup"),
    event: value("--type-event"),
    stroke: value("--marker-stroke")
  }
}

for (const layer of ["clusters", "place"]) {
  map.on("mouseenter", layer, () => { map.getCanvas().style.cursor = "pointer" })
  map.on("mouseleave", layer, () => { map.getCanvas().style.cursor = "" })
}

map.on("click", "clusters", async (event) => {
  const cluster = event.features[0]
  const zoom = await map.getSource("places").getClusterExpansionZoom(cluster.properties.cluster_id)
  map.easeTo({ center: cluster.geometry.coordinates, zoom })
})

map.on("click", "place", (event) => {
  const feature = features.find((candidate) => candidate.id === event.features[0].id)
  if (feature) select(feature)
})

map.on("moveend", () => {
  if (inView.checked) renderList()
})

// Filtering

search.addEventListener("input", update)
filters.addEventListener("change", update)
inView.addEventListener("change", renderList)

function update() {
  map.getSource("places")?.setData(featureCollection(visibleFeatures()))
  renderList()
}

function visibleFeatures() {
  const type = filters.elements.type.value
  const query = normalize(search.value.trim())

  return features.filter(({ properties }) => {
    if (type !== "all" && properties.type !== type) return false
    if (!query) return true
    return normalize(`${properties.name} ${properties.address} ${properties.description || ""}`).includes(query)
  })
}

function normalize(text) {
  return text.normalize("NFD").replace(/\p{Diacritic}/gu, "").toLowerCase()
}

function featureCollection(features) {
  return { type: "FeatureCollection", features }
}

// Panel

function renderCounts() {
  const counts = { all: features.length, business: 0, meetup: 0, event: 0 }
  for (const { properties } of features) counts[properties.type] = (counts[properties.type] || 0) + 1

  for (const element of filters.querySelectorAll("[data-count]")) {
    element.textContent = counts[element.dataset.count]
  }
}

function renderList() {
  let places = visibleFeatures()

  if (inView.checked) {
    const bounds = map.getBounds()
    places = places.filter((feature) => bounds.contains(feature.geometry.coordinates))
  }

  places.sort(comparePlaces)

  listHeading.textContent = places.length === 1 ? "1 place" : `${places.length} places`
  emptyMessage.hidden = places.length > 0
  emptyMessage.textContent = inView.checked ? "Nothing here matches. Zoom out or move the map to see more." : "Nothing matches. Try another name or place."
  list.replaceChildren(...places.map(renderPlace))
}

// Alphabetical by name, ignoring case and accents, then by address.
const collator = new Intl.Collator(undefined, { sensitivity: "base", numeric: true })

function comparePlaces(a, b) {
  return collator.compare(a.properties.name, b.properties.name) || collator.compare(a.properties.address, b.properties.address)
}

function renderPlace(feature) {
  const { name, address, type } = feature.properties
  const item = document.createElement("li")
  const button = element("button", `place place--${type}`)
  button.type = "button"
  button.dataset.id = feature.id
  if (feature.id === selectedId) button.setAttribute("aria-current", "true")

  const text = element("span", "place__text")
  text.append(element("span", "place__name", name), element("span", "place__address", address))
  button.append(renderMark(feature.properties, "place__mark"), text)
  button.addEventListener("click", () => {
    collapsePanel()
    fitPadding()
    select(feature, { fly: true })
  })

  item.append(button)
  return item
}

// A logo on a light tile, or the initials on the type colour when there is no logo.
function renderMark({ name, type, logo }, className) {
  const mark = element("span", `mark mark--${type} ${className}`)
  mark.title = TYPE_LABELS[type]

  if (logo) {
    const image = element("img")
    image.src = logo
    image.alt = ""
    image.loading = "lazy"
    image.decoding = "async"
    mark.append(image)
  } else {
    mark.classList.add("mark--initials")
    mark.textContent = initials(name)
  }

  return mark
}

function initials(name) {
  const words = name.replace(/\.rb\b/gi, "").replace(/[^\p{L}\p{N}\s]/gu, " ").split(/\s+/)
    .filter((word) => word && !/^(ruby|rails|on|the|of|and|meetup|user|users|group|rug)$/i.test(word))
  const letters = words.length > 1 ? words.slice(0, 2).map((word) => [...word][0]) : [...(words[0] || name)].slice(0, 2)
  return letters.join("").toUpperCase()
}


panelToggle.addEventListener("click", () => {
  const expanded = panel.classList.toggle("is-expanded")
  panelToggle.setAttribute("aria-expanded", expanded)
})

function collapsePanel() {
  panel.classList.remove("is-expanded")
  panelToggle.setAttribute("aria-expanded", "false")
}

// Selection

function select(feature, { fly = false } = {}) {
  selectedId = feature.id
  const coordinates = feature.geometry.coordinates

  // Put the place below the centre so the card above it fits on screen.
  const offset = [0, feature.properties.photo ? 190 : 110]
  if (fly) map.flyTo({ center: coordinates, offset, zoom: Math.max(map.getZoom(), CLUSTER_MAX_ZOOM + 2), essential: true })
  else map.easeTo({ center: coordinates, offset })

  popup?.remove()
  popup = new Popup({ anchor: "bottom", offset: 12, maxWidth: "320px", focusAfterOpen: false })
    .setLngLat(coordinates)
    .setDOMContent(renderPopup(feature.properties))
    .addTo(map)

  popup.on("close", () => {
    if (selectedId === feature.id) selectedId = null
    markSelected()
  })

  markSelected()
}

function markSelected() {
  for (const button of list.querySelectorAll(".place")) {
    if (Number(button.dataset.id) === selectedId) button.setAttribute("aria-current", "true")
    else button.removeAttribute("aria-current")
  }
}

function renderPopup(properties) {
  const { name, address, type, url, twitter_handle, description, photo, source } = properties
  const popup = element("article", `popup popup--${type}${photo ? " popup--photo" : ""}`)
  const website = safeUrl(url)

  if (photo) {
    const image = element("img", "popup__photo")
    image.src = photo
    image.alt = ""
    image.width = 600
    image.height = 350
    image.decoding = "async"
    popup.append(image)
  }

  const body = element("div", "popup__body")
  const heading = element("h3", "popup__name")
  if (website) {
    heading.append(externalLink(website.href, name))
  } else {
    heading.textContent = name
  }

  const head = element("div", "popup__head")
  head.append(renderMark(properties, "popup__mark"), element("span", "popup__type", TYPE_LABELS[type]))
  body.append(head, heading)
  if (description) body.append(element("p", "popup__description", description))
  body.append(element("p", "popup__address", address))

  const links = element("div", "popup__links")
  if (website) links.append(externalLink(website.href, website.hostname.replace(/^www\./, "")))
  if (twitter_handle) links.append(externalLink(`https://x.com/${encodeURIComponent(twitter_handle)}`, `@${twitter_handle}`))
  if (links.childElementCount) body.append(links)

  const rubyEvents = source?.match(/^rubyevents:(.+)$/)
  if (rubyEvents) {
    const credit = element("p", "popup__credit", "Listed on ")
    credit.append(externalLink(`https://www.rubyevents.org/events/${encodeURIComponent(rubyEvents[1])}`, "RubyEvents.org"))
    body.append(credit)
  }

  popup.append(body)
  return popup
}


function externalLink(href, text) {
  const link = element("a", null, text)
  link.href = href
  link.target = "_blank"
  link.rel = "noopener"
  return link
}

function safeUrl(value) {
  try {
    const url = new URL(value)
    return ["http:", "https:"].includes(url.protocol) ? url : null
  } catch {
    return null
  }
}

function element(tag, className, text) {
  const node = document.createElement(tag)
  if (className) node.className = className
  if (text != null) node.textContent = text
  return node
}
