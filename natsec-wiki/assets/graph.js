function (el, x) {
  // Controller for the main knowledge graph (graph.qmd): domain, code title, and layer
  // focus; node and edge selection; the layered view; full screen; phone sizing; and the
  // linked connections table.
  // visNetwork keeps the vis.Network on an inner element named "graph" + the widget id
  var canvasBox = document.getElementById("graph" + el.id);
  var net = canvasBox.chart;
  var nodesDS = net.body.data.nodes;
  var edgesDS = net.body.data.edges;
  var base = {}, ebase = {};
  nodesDS.get().forEach(function (n) { base[n.id] = n; });
  edgesDS.get().forEach(function (e) { ebase[e.id] = e; });

  var state = { domains: [], title: "", layer: "", selected: null, edge: null, view: "network", full: false };
  var FADE = "#e4e7ec", FADE_BORDER = "#cdd2d9", FADE_TEXT = "#b4bac3", INK = "#1b2a41";

  var phoneMQ = window.matchMedia("(max-width: 767.98px)");
  function isPhone() { return phoneMQ.matches; }

  // htmlwidgets refits the graph on every window resize. On phones the address bar showing
  // or hiding fires one, which would throw away the reader's zoom, so only a width change refits.
  var realFit = net.fit.bind(net);
  var fitWidth = el.clientWidth;
  net.fit = function (opts) {
    if (el.clientWidth === fitWidth) return;
    fitWidth = el.clientWidth;
    realFit(opts);
  };

  function hideHistoric() { return window.wikiHideHistoric ? window.wikiHideHistoric() : false; }

  function matches(n) {
    if (!n) return false;
    if (state.domains.length && state.domains.indexOf(n.domain) < 0) return false;
    if (state.title && ("," + n.titles + ",").indexOf("," + state.title + ",") < 0) return false;
    if (state.layer && n.layer !== state.layer) return false;
    return true;
  }
  function focusActive() { return state.domains.length || state.title || state.layer; }

  function nodeColor(c) {
    return { background: c, border: c, highlight: { background: c, border: INK }, hover: { background: c, border: INK } };
  }
  var faded = { background: FADE, border: FADE_BORDER, highlight: { background: FADE, border: INK }, hover: { background: FADE, border: FADE_BORDER } };

  // which nodes count as in view: focus filters, then the selection's neighborhood
  function neighborhood() {
    if (!state.selected) return null;
    return net.getConnectedNodes(state.selected).concat([state.selected]);
  }

  function apply() {
    var hide = hideHistoric();
    var near = neighborhood();
    nodesDS.update(Object.keys(base).map(function (id) {
      var n = base[id];
      var on = matches(n) && (!near || near.indexOf(id) >= 0);
      if (near && id === state.selected) on = true;
      return { id: id, hidden: !!(hide && n.historic), color: on ? nodeColor(n.basecolor) : faded,
               font: { color: on ? INK : FADE_TEXT } };
    }));
    edgesDS.update(Object.keys(ebase).map(function (id) {
      var e = ebase[id], a = base[e.from], b = base[e.to];
      var on = near ? (e.from === state.selected || e.to === state.selected)
                    : (!focusActive() || matches(a) || matches(b));
      // in the layered view, thematic links recede so the dependency chains stand out
      if (on && !near && state.view === "layers" && e.relation === "related") on = false;
      if (id === state.edge) on = true;
      return { id: id, hidden: !!(hide && (a.historic || b.historic)),
               color: { color: on ? e.basecolor : "rgba(205,210,217,0.35)", highlight: e.basecolor, hover: e.basecolor },
               width: id === state.edge ? 3.4 : (on && near ? 2.6 : 1.6) };
    }));
    syncControls();
    showInfo();
    drawTable();
  }

  // controls ------------------------------------------------------------------
  var root = document.getElementById("graph-controls");
  var stage = document.getElementById("graph-stage");

  function syncControls() {
    if (!root) return;
    root.querySelectorAll("[data-domain]").forEach(function (b) {
      var on = state.domains.indexOf(b.getAttribute("data-domain")) >= 0;
      b.classList.toggle("active", on);
      b.setAttribute("aria-pressed", on ? "true" : "false");
    });
    root.querySelector("#graph-title").value = state.title;
    root.querySelector("#graph-layer").value = state.layer;
    root.querySelector("#graph-find").value = state.selected || "";
    root.querySelectorAll("[data-view]").forEach(function (b) {
      b.classList.toggle("active", b.getAttribute("data-view") === state.view);
    });
    var full = document.getElementById("graph-full");
    if (full) {
      full.textContent = state.full ? "Close full screen" : "Full screen";
      full.setAttribute("aria-pressed", state.full ? "true" : "false");
    }
  }

  if (root) {
    root.querySelectorAll("[data-domain]").forEach(function (b) {
      b.addEventListener("click", function () {
        var d = b.getAttribute("data-domain"), i = state.domains.indexOf(d);
        if (i >= 0) state.domains.splice(i, 1); else state.domains.push(d);
        apply();
      });
    });
    root.querySelector("#graph-title").addEventListener("change", function (e) { state.title = e.target.value; apply(); });
    root.querySelector("#graph-layer").addEventListener("change", function (e) { state.layer = e.target.value; apply(); });
    root.querySelector("#graph-find").addEventListener("change", function (e) { select(e.target.value || null, true); });
    root.querySelector("#graph-reset").addEventListener("click", function () {
      state.domains = []; state.title = ""; state.layer = ""; state.selected = null; state.edge = null;
      net.unselectAll(); apply(); fitView(true);
    });
    root.querySelectorAll("[data-view]").forEach(function (b) {
      b.addEventListener("click", function () { setView(b.getAttribute("data-view")); });
    });
  }
  var fullBtn = document.getElementById("graph-full");
  if (fullBtn) fullBtn.addEventListener("click", function () { setFull(!state.full); });

  function select(id, zoom) {
    state.selected = id && base[id] ? id : null;
    state.edge = null;
    if (state.selected) {
      net.selectNodes([state.selected]);
      if (zoom) net.focus(state.selected, { scale: 0.9, animation: true });
    } else {
      net.unselectAll();
    }
    apply();
  }

  // a tap or click picks a statute, or a line to explain it, or clears both on empty canvas
  net.on("click", function (p) {
    if (p.nodes.length) select(p.nodes[0], false);
    else if (p.edges.length) { state.edge = p.edges[0]; apply(); }
    else if (state.selected || state.edge) select(null, false);
  });
  net.on("doubleClick", function (p) {
    if (p.nodes.length) window.location.href = base[p.nodes[0]].url;
  });

  // the selected statute or line, described beside the graph (a bottom sheet on phones)
  function showInfo() {
    var box = document.getElementById("graph-info");
    if (!box) return;
    var e = state.edge && ebase[state.edge];
    var close = "<button type=\"button\" class=\"graph-info-close\" aria-label=\"Close\">&times;</button>";
    box.classList.toggle("has-selection", !!(state.selected || e));
    if (e) {
      var a = base[e.from], b = base[e.to];
      box.innerHTML = close +
        "<div class=\"graph-info-head\"><span class=\"line-swatch\" style=\"border-color:" + e.basecolor + "\"></span>" +
        "<strong>" + a.label + " " + e.relation_label + " " + b.label + "</strong></div>" +
        "<p>" + e.note + "</p>" +
        "<p class=\"graph-info-links\">Open <a href=\"" + a.url + "\">" + a.label + "</a> or <a href=\"" + b.url + "\">" + b.label + "</a></p>";
    } else if (state.selected) {
      var n = base[state.selected];
      var count = net.getConnectedEdges(state.selected).length;
      box.innerHTML = close +
        "<div class=\"graph-info-head\"><span class=\"swatch\" style=\"background:" + n.basecolor + "\"></span>" +
        "<strong>" + n.fulltitle + "</strong></div>" +
        "<div class=\"graph-info-meta\">" + n.year + " · " + n.status_label + " · " + n.layer_label + " · " + n.domain_label + "</div>" +
        "<p>" + n.blurb + "</p>" +
        "<p class=\"graph-info-links\"><a href=\"" + n.url + "\">Open the wiki page</a>" +
        (n.official ? " · <a href=\"" + n.official + "\" target=\"_blank\" rel=\"noopener\">Read the official text</a>" : "") +
        " · " + count + " connection" + (count === 1 ? "" : "s") + "</p>";
    } else {
      box.innerHTML = "<p class=\"graph-info-empty\">Select a statute to see what it is and to filter the table below to its connections. " +
        "Select a line to see why two statutes are linked. Double-click or double-tap a statute to open its page.</p>";
    }
    var btn = box.querySelector(".graph-info-close");
    if (btn) btn.addEventListener("click", function () { select(null, false); });
  }

  // sizing: desktop, phone, and full screen ----------------------------------------
  var DESKTOP_H = el.style.height || "760px";

  function targetHeight() {
    if (state.full) {
      // fill the screen below the controls
      return Math.max(280, Math.floor(window.innerHeight - el.getBoundingClientRect().top - 8)) + "px";
    }
    if (isPhone()) {
      // the network is wider than tall, so a squarish canvas wastes less space; the layered
      // view is a tall stack and gets most of the screen
      if (state.view === "layers") return Math.max(360, Math.round(window.innerHeight * 0.75)) + "px";
      return Math.max(340, Math.min(Math.round(el.clientWidth * 1.2), Math.round(window.innerHeight * 0.62))) + "px";
    }
    return state.view === "layers" ? "1150px" : DESKTOP_H;
  }

  // size the widget container itself, so nothing below the graph is overlapped
  function resize() {
    var h = targetHeight();
    if (el.style.height === h) return false;
    el.style.height = h;
    net.setSize("100%", "100%");
    net.redraw();
    return true;
  }

  function fitView(animate) {
    var anim = animate ? { duration: 300 } : false;
    if (state.view === "layers" && isPhone() && bands.length) {
      // on a phone, fit the bands' width and start at the top of the stack
      var half = (cols() * COL_W) / 2 + 60;
      var scale = canvasBox.clientWidth / (2 * half);
      net.moveTo({ position: { x: 0, y: bands[0].top - 20 + (canvasBox.clientHeight / 2) / scale }, scale: scale, animation: anim });
    } else {
      realFit(animate ? { animation: anim } : undefined);
    }
    fitWidth = el.clientWidth;
  }

  function setFull(on) {
    state.full = on;
    if (stage) stage.classList.toggle("is-full", on);
    document.body.classList.toggle("graph-full-open", on);
    syncControls();
    // let the new layout settle before measuring
    setTimeout(function () { resize(); fitView(false); }, 30);
  }

  document.addEventListener("keydown", function (e) {
    if (e.key === "Escape" && state.full) setFull(false);
  });

  // Recompute the canvas only when the width changes (rotation, desktop resize) or in full
  // screen. A height-only change is the phone address bar, and following it would make the
  // page jump while the reader scrolls.
  var layoutWidth = el.clientWidth, resizeTimer = null;
  window.addEventListener("resize", function () {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(function () {
      var widthChanged = el.clientWidth !== layoutWidth;
      layoutWidth = el.clientWidth;
      if (widthChanged && state.view === "layers") layerLayout();
      if (widthChanged || state.full) resize();
      if (widthChanged) fitView(false);
    }, 150);
  });

  // layered view ----------------------------------------------------------------
  // Each layer is a band; its statutes wrap into rows sorted by domain, then year.
  var LAYER_NAMES = { 0: "Constitution", 1: "Framework statutes", 2: "Specific authorizations", 3: "Targeted provisions", 4: "U.S. Code titles" };
  var DOMAIN_ORDER = ["foundations", "war-powers", "intelligence", "defense-arms", "aid-sanctions", "civilian-protection", "foreign-policy"];
  var COL_W = 250, ROW_H = 100, BAND_GAP = 170;
  // fewer, taller columns on a phone so the labels stay readable at full width
  function cols() { return isPhone() ? 3 : 7; }
  var savedPositions = null, bands = [];

  function layerLayout() {
    var hide = hideHistoric();
    var COLS = cols();
    var byLevel = {};
    Object.keys(base).forEach(function (id) {
      var n = base[id];
      if (hide && n.historic) return;
      (byLevel[n.level] = byLevel[n.level] || []).push(n);
    });
    var y = 0, updates = [];
    bands = [];
    Object.keys(byLevel).sort().forEach(function (lvl) {
      var list = byLevel[lvl].sort(function (a, b) {
        return (DOMAIN_ORDER.indexOf(a.domain) - DOMAIN_ORDER.indexOf(b.domain)) || (a.year - b.year);
      });
      var rows = Math.ceil(list.length / COLS);
      bands.push({ level: +lvl, top: y - ROW_H / 2 - 40, bottom: y + (rows - 1) * ROW_H + ROW_H / 2 });
      list.forEach(function (n, i) {
        var inRow = Math.min(COLS, list.length - Math.floor(i / COLS) * COLS);
        updates.push({ id: n.id, x: ((i % COLS) - (inRow - 1) / 2) * COL_W, y: y + Math.floor(i / COLS) * ROW_H });
      });
      y += rows * ROW_H + BAND_GAP;
    });
    nodesDS.update(updates);
  }

  function setView(v) {
    if (v === state.view) return;
    state.view = v;
    if (v === "layers") {
      savedPositions = net.getPositions();
      net.setOptions({ physics: { enabled: false }, edges: { smooth: { type: "cubicBezier", forceDirection: "vertical", roundness: 0.35 } } });
      layerLayout();
    } else {
      net.setOptions({ edges: { smooth: { type: "continuous" } } });
      if (savedPositions) {
        nodesDS.update(Object.keys(savedPositions).map(function (id) {
          return { id: id, x: savedPositions[id].x, y: savedPositions[id].y };
        }));
      }
      net.setOptions({ physics: { enabled: true } });
    }
    resize();
    apply();
    net.redraw();
    // fit once the resized canvas has been drawn
    setTimeout(function () { fitView(false); }, 60);
  }

  // shade and label each band in the layered view
  net.on("beforeDrawing", function (ctx) {
    if (state.view !== "layers") return;
    var half = (cols() * COL_W) / 2 + 60;
    ctx.save();
    bands.forEach(function (b, i) {
      ctx.fillStyle = i % 2 ? "#f4f6f9" : "#eaeef3";
      ctx.fillRect(-half, b.top, 2 * half, b.bottom - b.top);
      ctx.font = "700 28px Segoe UI, Helvetica Neue, Arial, sans-serif";
      ctx.fillStyle = "#1b2a41";
      ctx.textAlign = "left";
      ctx.fillText(LAYER_NAMES[b.level], -half + 16, b.top + 32);
    });
    ctx.restore();
  });

  // the connections table -----------------------------------------------------------
  function tableEl() { return window.jQuery && window.jQuery("#conn-table table.dataTable"); }

  if (window.jQuery && window.jQuery.fn.dataTable) {
    window.jQuery.fn.dataTable.ext.search.push(function (settings, data) {
      if (!settings.nTable.closest || !settings.nTable.closest("#conn-table")) return true;
      var f = base[data[4]], t = base[data[5]];
      if (!f || !t) return true;
      if (hideHistoric() && (f.historic || t.historic)) return false;
      if (state.selected) return data[4] === state.selected || data[5] === state.selected;
      if (focusActive()) return matches(f) || matches(t);
      return true;
    });
  }

  function drawTable() {
    var t = tableEl();
    if (!t || !t.length) return;
    var api = t.DataTable();
    api.draw();
    var label = document.getElementById("conn-status");
    if (!label) return;
    var shown = api.page.info().recordsDisplay, total = api.page.info().recordsTotal;
    var what = state.selected ? "connections of " + base[state.selected].label
             : focusActive() ? "connections touching the focused statutes" : "all connections";
    label.innerHTML = "Showing " + shown + " of " + total + " (" + what + ")" +
      (state.selected || focusActive() ? " <button type=\"button\" class=\"link-button\" id=\"conn-clear\">Show all</button>" : "");
    var clear = document.getElementById("conn-clear");
    if (clear) clear.addEventListener("click", function () { root.querySelector("#graph-reset").click(); });
  }

  // the table may initialize after the graph
  if (window.jQuery) window.jQuery(document).on("init.dt", function () { drawTable(); });

  document.addEventListener("wiki:historic", function () {
    apply();
    if (state.view === "layers") { layerLayout(); fitView(true); }
  });

  // links can preset the view: ?focus=<id>, ?domain=<key>[,<key>], ?title=<n>, ?layer=<key>, ?view=layers
  var params = new URLSearchParams(window.location.search);
  if (params.get("domain")) state.domains = params.get("domain").split(",").filter(function (d) {
    return Object.keys(base).some(function (id) { return base[id].domain === d; });
  });
  if (params.get("title")) state.title = params.get("title");
  if (params.get("layer")) state.layer = params.get("layer");
  // phones get a shorter canvas than the 760px desktop default
  resize();
  net.once("stabilizationIterationsDone", function () {
    var focus = params.get("focus");
    if (params.get("view") === "layers") setView("layers");
    else fitView(false);
    if (focus && base[focus]) select(focus, true); else apply();
  });
  apply();
}
