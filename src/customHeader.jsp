<%@ include file="../assetsJsp/commonTaglib.jsp"%>
<div id="sitename">
  <div>
    <span class="sitetitle"><a href="?operation=UiV2Main.indexMain" onclick="return handleGuiV2LinkClick(event, 'operation=UiV2Main.indexMain');">${textContainer.text['kithAndKirr.siteTitle']}</a></span>
    <%-- Subtitle: kithAndKirr.siteTagline, none when it's blank or missing --%>
    <c:set var="kithAndKirrTagline" value="${textContainer.text['kithAndKirr.siteTagline']}" />
    <c:if test="${not empty kithAndKirrTagline and not kithAndKirrTagline.startsWith('$$')}"><h2>${kithAndKirrTagline}</h2></c:if>
  </div><%-- The logo repeats the site name's link, so screen readers and the keyboard skip it --%><a href="?operation=UiV2Main.indexMain" onclick="return handleGuiV2LinkClick(event, 'operation=UiV2Main.indexMain');" aria-hidden="true" tabindex="-1"><img src="../../grouperExternal/public/assets/kith-and-kirr/cmu-grouper-logo.svg" width="161" height="80" alt="" /></a>
</div>
<div class="kith-and-kirr-footer" role="contentinfo">
  <div>
    <p>${textContainer.text['kithAndKirr.siteTitle']}<br />${textContainer.text['institutionName']}<br />5000 Forbes Avenue<br />Pittsburgh, PA 15213</p>
    <ul>
      <li><a href="?operation=UiV2Main.help" onclick="return handleGuiV2LinkClick(event, 'operation=UiV2Main.help');">${textContainer.text['grouper.help']}</a></li>
      <li><a href="https://www.cmu.edu/legal/">Legal Info</a></li>
      <li><a href="https://www.cmu.edu/">www.cmu.edu</a></li>
    </ul>
    <ul>
      <li>&copy; <%= java.time.Year.now() %> ${textContainer.text['institutionName']}</li>
    </ul>
  </div>
</div>
<%-- Text for the header scripts, escaped into attributes the scripts read --%>
<span hidden id="kith-and-kirr-text" data-summary-less="${fn:escapeXml(textContainer.text['kithAndKirr.summaryLess'])}"></span>
<script>
  // The current page's name (Grouper's grouperJspClass) on the main content,
  // for styles that apply to one page; Grouper replaces the content by Ajax
  (function () {
    function mark() {
      var main = document.getElementById("grouperMainContentDivId");
      if (!main) return;
      var page = main.querySelector(".grouperJspClass");
      var name = page ? page.textContent.trim() : "";
      if (main.getAttribute("data-kith-and-kirr-page") !== name) main.setAttribute("data-kith-and-kirr-page", name);
    }
    mark();
    new MutationObserver(mark).observe(document.body, { childList: true, subtree: true });
  })();
</script>
<script>
  // A text box with an accessible name but no placeholder shows its name as
  // the placeholder; Grouper loads pages by Ajax, so new content is watched
  (function () {
    function fill(root) {
      root.querySelectorAll('input[type="text"][aria-label]:not([placeholder])').forEach(function (input) {
        input.placeholder = input.getAttribute("aria-label");
      });
    }
    fill(document);
    new MutationObserver(function () { fill(document); }).observe(document.body, { childList: true, subtree: true });
  })();
</script>
<script>
  // The theme's favicon in place of Grouper's: an SVG, a PNG for browsers
  // without SVG icons and a touch icon
  (function () {
    var base = "../../grouperExternal/public/assets/kith-and-kirr/";
    document.querySelectorAll('link[rel~="icon"], link[rel="apple-touch-icon"]').forEach(function (link) { link.remove(); });
    [["icon", "favicon.svg", "image/svg+xml"], ["icon", "favicon-32.png", "image/png"], ["apple-touch-icon", "apple-touch-icon.png", ""]].forEach(function (icon) {
      var link = document.createElement("link");
      link.rel = icon[0];
      link.href = base + icon[1];
      if (icon[2]) link.type = icon[2];
      if (icon[1] === "favicon-32.png") link.sizes = "32x32";
      document.head.appendChild(link);
    });
  })();
</script>
<script>
  // The signed-in user's initials in the roof, in place of a photo
  (function () {
    function initials() {
      var link = document.querySelector('.navbar-text a[href*="UiV2Subject.viewSubject"]');
      if (!link || link.hasAttribute("data-initials")) return;
      var words = link.textContent.trim().split(/\s+/);
      link.setAttribute("data-initials", (words[0].charAt(0) + (words.length > 1 ? words[words.length - 1].charAt(0) : "")).toUpperCase());
    }
    initials();
    new MutationObserver(initials).observe(document.body, { childList: true, subtree: true });
  })();
</script>
<script>
  // Each list table cell gets its column's heading, the label it shows when
  // the table stacks on phones; a table with one named column gets none, and
  // checkbox and actions cells get none
  (function () {
    function label() {
      document.querySelectorAll("table.data-table").forEach(function (table) {
        var head = table.querySelector("thead tr:has(> th)");
        if (!head) return;
        var names = Array.prototype.map.call(head.children, function (th) { return th.textContent.trim(); });
        if (names.filter(Boolean).length < 2) return;
        table.querySelectorAll("tbody > tr").forEach(function (row) {
          Array.prototype.forEach.call(row.children, function (cell, i) {
            if (names[i] && !cell.hasAttribute("data-label") && !cell.querySelector('input[type="checkbox"], .btn-group')) cell.setAttribute("data-label", names[i]);
          });
        });
      });
    }
    label();
    new MutationObserver(label).observe(document.body, { childList: true, subtree: true });
  })();
</script>
<script>
  // After Show more information, a link that goes back to the plain summary
  (function () {
    var source = document.getElementById("kith-and-kirr-text");
    var text = source ? source.getAttribute("data-summary-less") || "" : "";
    if (!text || text.indexOf("$$") === 0) text = "Hide more information";
    function addHide() {
      document.querySelectorAll('[id$="SummaryMoreId"]').forEach(function (more) {
        if (more.style.display !== "none" || (more.nextElementSibling && more.nextElementSibling.classList.contains("kith-and-kirr-summary-less"))) return;
        var show = more.querySelector("a");
        var match = show && /\.\.\/app\/(UiV2\w+)\.(view\w+?)SummaryMore\?([^']+)'/.exec(show.getAttribute("onclick") || "");
        if (!match) return;
        var less = document.createElement("span");
        less.className = "kith-and-kirr-summary-less";
        var link = document.createElement("a");
        link.href = "#";
        var icon = document.createElement("i");
        icon.className = "fa fa-angle-up";
        icon.setAttribute("aria-hidden", "true");
        link.textContent = text + " ";
        link.appendChild(icon);
        link.addEventListener("click", function (event) {
          event.preventDefault();
          guiV2link("operation=" + match[1] + "." + match[2] + "&" + match[3]);
        });
        less.appendChild(link);
        more.parentNode.insertBefore(less, more.nextSibling);
      });
    }
    new MutationObserver(addHide).observe(document.body, { childList: true, subtree: true, attributes: true, attributeFilter: ["style"] });
  })();
</script>
<script>
  // Grouper's pager ("Showing 11-20 of 21, First | Prev | Next | Last") as
  // the Kilt's results count and pager: arrows, then a number for each page,
  // each running Grouper's own paging request
  (function () {
    function item(cls, label, text, onclick, current) {
      var li = document.createElement("li");
      if (cls) li.className = cls;
      var a = document.createElement("a");
      if (label) a.setAttribute("aria-label", label);
      if (/[\u00ab\u2039\u203a\u00bb]/.test(text)) a.className = "cmu-pager-arrow";
      a.textContent = text;
      if (current) {
        a.href = "#";
        a.setAttribute("aria-current", "page");
        a.addEventListener("click", function (event) { event.preventDefault(); });
      } else if (onclick) {
        a.href = "#";
        a.setAttribute("onclick", onclick);
      } else {
        a.setAttribute("aria-disabled", "true");
      }
      li.appendChild(a);
      return li;
    }
    function rebuild() {
      document.querySelectorAll(".data-table-bottom > .pull-right:not([data-kk-pager])").forEach(function (old) {
        var match = /Showing\s+(\d+)-(\d+)\s+of\s+(\d+)/.exec(old.textContent);
        if (!match) return;
        old.setAttribute("data-kk-pager", "");
        var first = +match[1], last = +match[2], total = +match[3];
        var links = {};
        old.querySelectorAll("a").forEach(function (a) { links[a.textContent.trim()] = a.getAttribute("onclick"); });
        var template = links.Next || links.Prev || links.Last || "";
        var size = last - first + 1;
        var form = old.parentElement.querySelector("select[name='pagingTagPageSize']");
        if (form) size = +form.value || size;
        var pages = Math.max(1, Math.ceil(total / (size || 1)));
        var current = Math.max(1, Math.ceil(first / (size || 1)));
        function go(n) {
          if (!template) return null;
          return /pagingTagPageNumber=\d+/.test(template)
            ? template.replace(/pagingTagPageNumber=\d+/, "pagingTagPageNumber=" + n)
            : null;
        }
        var count = document.createElement("p");
        count.className = "cmu-results-count";
        count.textContent = pages === 1 ? "Showing all " + total : "Showing " + first + "-" + last + " of " + total;
        var pager = document.createElement("div");
        pager.className = "cmu-pager";
        pager.setAttribute("role", "navigation");
        pager.setAttribute("aria-label", "Pages");
        var ol = document.createElement("ol");
        ol.appendChild(item("cmu-pager-end", "First page", "\u00ab", links.First));
        ol.appendChild(item("", "Previous page", "\u2039", links.Prev));
        var shown = [];
        for (var n = 1; n <= pages; n++) {
          if (n === 1 || n === pages || Math.abs(n - current) <= 2) shown.push(n);
        }
        shown.forEach(function (n, i) {
          if (i && n - shown[i - 1] > 1) {
            var gap = document.createElement("li");
            gap.innerHTML = "<span>&hellip;</span>";
            ol.appendChild(gap);
          }
          ol.appendChild(item("", null, String(n), n === current ? null : (n === 1 ? links.First || go(1) : go(n)), n === current));
        });
        ol.appendChild(item("", "Next page", "\u203a", links.Next));
        ol.appendChild(item("cmu-pager-end", "Last page", "\u00bb", links.Last));
        pager.appendChild(ol);
        old.textContent = "";
        old.appendChild(count);
        old.appendChild(pager);
        // Grouper's Show menu as the Kilt's Page Size
        var sizeForm = old.parentElement.querySelector("form:has(select[name='pagingTagPageSize'])");
        if (sizeForm) {
          sizeForm.classList.add("cmu-page-size");
          var label = sizeForm.querySelector("label");
          if (label) label.textContent = "Rows per page";
        }
      });
    }
    rebuild();
    new MutationObserver(rebuild).observe(document.body, { childList: true, subtree: true });
  })();
</script>
<script>
  // The Kilt's selection count at the start of a list table's toolbar ("2
  // members selected"). The toolbar's buttons show only while rows are
  // selected, each with the count; the noun is the first button's last word
  (function () {
    function label(button) {
      var text = button.getAttribute("data-kith-and-kirr-label");
      if (!text) {
        text = button.textContent.trim();
        button.setAttribute("data-kith-and-kirr-label", text);
      }
      return text;
    }
    function update() {
      document.querySelectorAll("td.table-toolbar").forEach(function (bar) {
        var table = bar.closest("table");
        var buttons = bar.querySelectorAll(".btn");
        var boxes = table ? table.querySelectorAll("tbody input[type='checkbox']") : [];
        if (!buttons.length || !boxes.length) return;
        var n = Array.prototype.filter.call(boxes, function (box) { return box.checked; }).length;
        var words = label(buttons[0]).toLowerCase().split(/\s+/);
        var plural = words[words.length - 1];
        var singular = plural.replace(/s$/, "");
        var text = n === 0 ? "No " + plural + " selected" : n === 1 ? "1 " + singular + " selected" : n + " " + plural + " selected";
        var count = bar.querySelector(".cmu-selection-count");
        if (!count) {
          count = document.createElement("span");
          count.className = "cmu-selection-count";
          count.setAttribute("aria-live", "polite");
          bar.insertBefore(count, bar.firstChild);
        }
        if (count.textContent !== text) count.textContent = text;
        count.classList.toggle("cmu-has-selection", n > 0);
        Array.prototype.forEach.call(buttons, function (button) {
          var base = label(button);
          var want = n ? base + " (" + n + ")" : base;
          if (!button.children.length && button.textContent.trim() !== want) button.textContent = want;
          button.hidden = n === 0;
        });
      });
    }
    function later() { setTimeout(update, 0); }
    update();
    document.addEventListener("change", later);
    document.addEventListener("click", later);
    new MutationObserver(update).observe(document.body, { childList: true, subtree: true });
  })();
</script>
