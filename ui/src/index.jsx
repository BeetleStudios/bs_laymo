import React from "react"
import ReactDOM from "react-dom/client"
import App from "./App"

import "./colors.css"
import "./index.css"

const devMode = !window.invokeNative
const root = ReactDOM.createRoot(document.getElementById("root"))

const renderApp = () => {
    root.render(
        <React.StrictMode>
            <App />
        </React.StrictMode>
    )
}

if (devMode) {
    renderApp()
} else {
    // lb-phone sends "componentsLoaded" when the app iframe is ready (phone APIs injected).
    // Also render immediately with short delay so the app shows even if the event is missed or delayed.
    let rendered = false
    const doRender = () => {
        if (!rendered) {
            rendered = true
            renderApp()
        }
    }
    window.addEventListener("message", (event) => {
        const data = event.data
        if (data === "componentsLoaded" || data?.type === "componentsLoaded" || data?.event === "componentsLoaded") {
            doRender()
        }
    })
    // Render soon so the app is never stuck on a black screen (lb-phone may not send componentsLoaded in some versions)
    setTimeout(doRender, 300)
}
