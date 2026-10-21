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

// On wide screens the panel covers the left of the map, so centre the map in
// the area beside it.
const wideScreen = matchMedia("(min-width: 721px)")

function fitPadding() {
  const left = wideScreen.matches ? panel.getBoundingClientRect().right : 0
  map.setPadding({ left, top: 0, right: 0, bottom: 0 })
}

fitPadding()
wideScreen.addEventListener("change", fitPadding)

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
    return normalize(`${properties.name} ${properties.address}`).includes(query)
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

  listHeading.textContent = places.length === 1 ? "1 place" : `${places.length} places`
  emptyMessage.hidden = places.length > 0
  emptyMessage.textContent = inView.checked ? "Nothing here matches. Zoom out or move the map to see more." : "Nothing matches. Try another name or place."
  list.replaceChildren(...places.map(renderPlace))
}

function renderPlace(feature) {
  const { name, address, type } = feature.properties
  const item = document.createElement("li")
  const button = element("button", `place place--${type}`)
  button.type = "button"
  button.dataset.id = feature.id
  if (feature.id === selectedId) button.setAttribute("aria-current", "true")

  const dot = element("span", "place__dot")
  dot.title = TYPE_LABELS[type]

  button.append(dot, element("span", "place__name", name), element("span", "place__address", address))
  button.addEventListener("click", () => {
    select(feature, { fly: true })
    collapsePanel()
  })

  item.append(button)
  return item
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

  if (fly) map.flyTo({ center: coordinates, zoom: Math.max(map.getZoom(), CLUSTER_MAX_ZOOM + 2), essential: true })

  popup?.remove()
  popup = new Popup({ offset: 12, maxWidth: "300px", focusAfterOpen: false })
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

function renderPopup({ name, address, type, url, twitter_handle }) {
  const popup = element("div", `popup popup--${type}`)
  const heading = element("h3", "popup__name")
  const website = safeUrl(url)

  if (website) {
    const link = element("a", null, name)
    link.href = website.href
    link.target = "_blank"
    link.rel = "noopener"
    heading.append(link)
  } else {
    heading.textContent = name
  }

  popup.append(element("span", "popup__type", TYPE_LABELS[type]), heading, element("p", "popup__address", address))

  const links = element("div", "popup__links")
  if (website) links.append(externalLink(website.href, website.hostname.replace(/^www\./, "")))
  if (twitter_handle) links.append(externalLink(`https://x.com/${encodeURIComponent(twitter_handle)}`, `@${twitter_handle}`))
  if (links.childElementCount) popup.append(links)

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
