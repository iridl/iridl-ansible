// Progressive enhancement for the report file server's fancy directory
// listings (see index.css). Without it the plain Apache listing
// still works.
//
//  - Turns "Index of /reports/SouthEthiopia/OND" into a breadcrumb.
//  - Shows folder names readably: "SouthEthiopia" as "South Ethiopia",
//    and three-month season codes such as "OND" with their months.
//  - Says so when a folder is empty.

(function () {
  "use strict";

  var MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  var INITIALS = "JFMAMJJASONDJF";

  // "OND" -> "Oct-Dec"; null if the name isn't a season code.
  function season(name) {
    if (!/^[A-Z]{3}$/.test(name)) return null;
    var i = INITIALS.indexOf(name);
    return i < 0 ? null : MONTHS[i] + "\u2013" + MONTHS[(i + 2) % 12];
  }

  // "SouthEthiopia" -> "South Ethiopia", "Ethiopia_AA" -> "Ethiopia AA"
  function readable(name) {
    return name
      .replace(/_/g, " ")
      .replace(/([a-z])([A-Z])/g, "$1 $2");
  }

  function el(tag, cls, text) {
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text) e.textContent = text;
    return e;
  }

  function appendName(parent, name) {
    var s = season(name);
    if (!s) {
      parent.appendChild(document.createTextNode(readable(name)));
      return;
    }
    // Keep the code and its months together when the line wraps.
    var group = el("span", "seasongroup", name);
    group.appendChild(el("span", "season", s));
    parent.appendChild(group);
  }

  function breadcrumb(title) {
    var path = title.textContent.replace(/^Index of /, "");
    var parts = path.split("/").filter(Boolean).map(decodeURIComponent);
    if (!parts.length) return;

    // The top level is labeled from <meta name="fileserver-title">,
    // falling back to the capitalized URL segment.
    var meta = document.querySelector('meta[name="fileserver-title"]');
    var root = meta && meta.content ||
      parts[0].charAt(0).toUpperCase() + parts[0].slice(1);

    var names = [];
    title.textContent = "";
    parts.forEach(function (part, i) {
      var label = i === 0 ? root : part;
      if (i > 0) title.appendChild(el("span", "sep", "/"));
      var node;
      if (i < parts.length - 1) {
        node = el("a");
        node.href = "/" + parts.slice(0, i + 1).map(encodeURIComponent)
          .join("/") + "/";
      } else {
        node = el("span");
        node.setAttribute("aria-current", "page");
      }
      appendName(node, label);
      title.appendChild(node);
      names.push(readable(label));
    });
    document.title = names.slice().reverse().join(" \u2013 ");
  }

  function listing(table) {
    var entries = 0;
    var links = table.querySelectorAll("td.indexcolname a");
    Array.prototype.forEach.call(links, function (a) {
      var href = a.getAttribute("href");
      if (href.charAt(0) === "/") {
        a.textContent = "Up one level";
        return;
      }
      entries++;
      var name = a.textContent.replace(/\/$/, "");
      a.textContent = "";
      if (/\/$/.test(href)) {
        appendName(a, name);
      } else {
        // Let long file names wrap after underscores, not mid-word.
        name.split("_").forEach(function (piece, i) {
          if (i > 0) {
            a.appendChild(document.createTextNode("_"));
            a.appendChild(el("wbr"));
          }
          a.appendChild(document.createTextNode(piece));
        });
      }
      a.title = name;
    });

    if (!entries) {
      var row = el("tr", "indexempty");
      var cell = el("td", null, "This folder is empty. " +
        "Reports appear here once they are published.");
      cell.colSpan = 3;
      row.appendChild(cell);
      var rows = table.querySelectorAll("tr.indexbreakrow");
      var last = rows[rows.length - 1];
      last.parentNode.insertBefore(row, last);
    }
  }

  var title = document.getElementById("indextitle");
  var table = document.getElementById("indexlist");
  if (title) breadcrumb(title);
  if (table) listing(table);
})();
