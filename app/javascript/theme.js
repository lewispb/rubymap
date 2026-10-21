// The theme setting is "system", "light" or "dark". "system" follows the
// operating system; the others are stored and set as data-theme on <html>.
const SETTINGS = ["system", "light", "dark"]
const darkQuery = matchMedia("(prefers-color-scheme: dark)")

export function themeSetting() {
  return document.documentElement.dataset.theme || "system"
}

export function currentTheme() {
  const setting = themeSetting()
  if (setting === "system") return darkQuery.matches ? "dark" : "light"
  return setting
}

export function onThemeChange(callback) {
  darkQuery.addEventListener("change", () => callback(currentTheme()))
  document.addEventListener("theme:change", () => callback(currentTheme()))
}

function applySetting(setting) {
  if (setting === "system") {
    delete document.documentElement.dataset.theme
  } else {
    document.documentElement.dataset.theme = setting
  }

  try {
    if (setting === "system") localStorage.removeItem("theme")
    else localStorage.setItem("theme", setting)
  } catch {}

  renderToggle()
  document.dispatchEvent(new CustomEvent("theme:change"))
}

function renderToggle() {
  const toggle = document.getElementById("theme-toggle")
  if (!toggle) return

  const setting = themeSetting()
  const next = SETTINGS[(SETTINGS.indexOf(setting) + 1) % SETTINGS.length]
  toggle.dataset.themeSetting = setting
  toggle.title = toggle.ariaLabel = `Theme: ${setting}. Switch to ${next}.`
}

document.getElementById("theme-toggle")?.addEventListener("click", () => {
  const setting = themeSetting()
  applySetting(SETTINGS[(SETTINGS.indexOf(setting) + 1) % SETTINGS.length])
})

renderToggle()
