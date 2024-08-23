// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

function mousePositionInfo(e) {
  let { width, height } = e.target.getBoundingClientRect();
  let ret = {
    p: [e.offsetX, e.offsetY],
    np: [e.offsetX / width, e.offsetY / height]
  }
  return ret;
}

let Hooks = {};
Hooks.MouseHandler = {
  mounted() {

    this.el.addEventListener('wheel', e => {
      this.pushEventTo(`#${this.el.id}`, "mouse_wheel", { d: [e.deltaX, e.deltaY, e.deltaZ] });
      e.stopPropagation();
      e.preventDefault();
    })
    this.el.addEventListener('mouseleave', e => {
      this.pushEventTo(`#${this.el.id}`, "mouse_leave", mousePositionInfo(e));
    });
    this.el.addEventListener('mouseenter', e => {
      this.pushEventTo(`#${this.el.id}`, "mouse_enter", mousePositionInfo(e));
    });
    this.el.addEventListener('mousemove', e => {
      this.pushEventTo(`#${this.el.id}`, "mouse_move", mousePositionInfo(e));
    });
    this.el.addEventListener('mouseup', e => {
      this.pushEventTo(`#${this.el.id}`, "mouse_up", { ...mousePositionInfo(e), b: e.which });
    });
    this.el.addEventListener('mousedown', e => {
      this.pushEventTo(`#${this.el.id}`, "mouse_down", { ...mousePositionInfo(e), b: e.which });
      e.stopPropagation();
      e.preventDefault();
    });
    this.el.addEventListener('contextmenu', e => e.preventDefault());
  }
};

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken }
})

liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

