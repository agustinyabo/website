---
layout: page
title: publications
description: grouped by type and ordered by year
permalink: /hal/
nav: true
nav_order: 3
---

<div class="publications" id="hal-publications-container">Loading publications...</div>

<script>
function cleanName(text) {
  return text
    .replace(/Agustín Gabriel Yabo/g, "Agustín G. Yabo")
    .replace(/Agustín G Yabo/g, "Agustín G. Yabo")
    .replace(/Agustín G\.? Yabo/g, "Agustín G. Yabo")
    .replace(/Agustín G. Yabo/g, "<u>Agustín G. Yabo</u>");
}

function deduplicateAuthors(authors) {
  const seen = new Set();
  return authors.filter(name => {
    const trimmed = name.trim();
    if (seen.has(trimmed)) return false;
    seen.add(trimmed);
    return true;
  });
}

function parseTEI(xmlText) {
  var parser = new DOMParser();
  var xml = parser.parseFromString(xmlText, "text/xml");
  var NS = "http://www.tei-c.org/ns/1.0";
  var entries = Array.prototype.slice.call(xml.getElementsByTagNameNS(NS, "biblFull"));

  return entries.map(function(entry) {
    var titleNode = entry.getElementsByTagNameNS(NS, "title")[0];
    var title = titleNode ? titleNode.textContent.trim() : "";

    var rawAuthors = Array.prototype.slice.call(entry.getElementsByTagNameNS(NS, "author")).map(function(a) {
      var pers = a.getElementsByTagNameNS(NS, "persName")[0];
      if (!pers) return "";
      var name = Array.prototype.slice.call(pers.children).map(function(c) {
        return c.textContent.trim();
      }).join(" ");
      return cleanName(name.trim());
    });
    var authors = deduplicateAuthors(rawAuthors).join(", ");

    var idnos = Array.prototype.slice.call(entry.getElementsByTagNameNS(NS, "idno"));
    function getIdno(type) {
      for (var i = 0; i < idnos.length; i++) {
        if (idnos[i].getAttribute("type") === type) {
          return idnos[i].textContent.trim();
        }
      }
      return "";
    }

    var doi = getIdno("doi");
    var halId = getIdno("halId");
    var uri = getIdno("halUri") || ("https://hal.science/" + halId);

    var seeAlsoNode = entry.querySelector('ref[type="seeAlso"]');
    var seeAlso = seeAlsoNode ? seeAlsoNode.getAttribute("target") : "";

    var pdfNode = entry.querySelector('ref[type="file"][subtype="author"]');
    var pdf = pdfNode ? pdfNode.getAttribute("target") : (uri + "/document");

    var rawTypeNode = entry.querySelector('classCode[scheme="halTypology"]');
    var rawType = rawTypeNode ? rawTypeNode.textContent.trim() : "other";
    var rawTypeN = rawTypeNode ? rawTypeNode.getAttribute("n") : "";

    var typeMap = {
      "Journal articles": "journal articles",
      "Preprints, Working Papers, ...": "preprints",
      "Conference papers": "conference papers",
      "Book sections": "book sections",
      "Books": "books",
      "Theses": "phd thesis"
    };

    var type = typeMap[rawType] || "Other";
    if (rawTypeN === "THESE") {
      type = "phd thesis";
    }
    if (rawType === "Conference papers") {
      var procNote = entry.querySelector('note[type="proceedings"]');
      var inProceedings = procNote && procNote.getAttribute("n") === "1";
      type = inProceedings ? "conference paper (with proceedings)" : "talk (without proceedings)";
    }

    var dateNode = entry.querySelector('date[type="datePub"]') || entry.querySelector("date");
    var year = "";
    if (dateNode) {
      var when = dateNode.getAttribute("when");
      year = when ? when.slice(0, 4) : dateNode.textContent.trim().slice(0, 4);
    }

    var journal = "";
    if (
      rawType === "Conference papers" ||
      type.indexOf("Conference") === 0 ||
      type.indexOf("Talk") === 0
    ) {
      var confNameNode = entry.querySelector("meeting > title");
      var cityNode = entry.querySelector("meeting > settlement");
      var countryNode = entry.querySelector("meeting > country");
      var startNode = entry.querySelector('meeting > date[type="start"]');
      var confName = confNameNode ? confNameNode.textContent.trim() : "";
      var city = cityNode ? cityNode.textContent.trim() : "";
      var country = countryNode ? countryNode.textContent.trim() : "";
      journal = [confName, [city, country].filter(Boolean).join(", ")].filter(Boolean).join(", ");
      if (startNode) {
        year = startNode.textContent.trim().slice(0, 4);
      }
    } else if (type === "PhD Thesis") {
      var institutionNode = entry.querySelector('monogr > authority[type="institution"]');
      journal = institutionNode ? institutionNode.textContent.trim() : "";
    } else {
      var publisherNode = entry.querySelector("monogr > imprint > publisher") || entry.querySelector("publicationStmt > publisher");
      var monogrTitleNode = entry.querySelector("monogr > title");
      var publisher = publisherNode ? publisherNode.textContent.trim() : "";
      var monogrTitle = monogrTitleNode ? monogrTitleNode.textContent.trim() : "";
      if (type === "Books") journal = publisher || "Book";
      else if (type === "Book sections") journal = monogrTitle || publisher;
      else journal = monogrTitle || publisher;
    }

    journal = journal.trim();

    return {
      title: title,
      authors: authors,
      journal: journal,
      year: year,
      uri: uri,
      pdf: pdf,
      type: type,
      doi: doi,
      seeAlso: seeAlso
    };
  });
}


function groupByType(entries) {
  return entries.reduce((acc, e) => {
    const t = e.type;
    acc[t] = acc[t] || [];
    acc[t].push(e);
    return acc;
  }, {});
}

fetch("https://api.archives-ouvertes.fr/search/hal/?wt=xml-tei&rows=1000&sort=publicationDate_tdate%20desc&q=authIdHal_s:agustin-gabriel-yabo")
  .then(r => r.text())
  .then(xmlText => {
    const parsed = parseTEI(xmlText);
    const grouped = groupByType(parsed);
    const desiredOrder = [
      "preprints",
      "journal articles",
      "conference paper (with proceedings)",
      "talk (without proceedings)",
      "books",
      "book sections",
      "phd thesis",
      "other"
    ];
    const types = Object.keys(grouped).sort((a, b) => desiredOrder.indexOf(a) - desiredOrder.indexOf(b));

    types.forEach(type => {
      grouped[type].sort((a, b) => (b.year || "").localeCompare(a.year || ""));
    });

    const container = document.getElementById("hal-publications-container");
    container.innerHTML = "";

    types.forEach(type => {
      const pubs = grouped[type];
      const hr = document.createElement("div");
      hr.className = "row";
      hr.innerHTML = `<div class="col-12"><hr></div>`;
      container.appendChild(hr);

      pubs.forEach((e, i) => {
        const row = document.createElement("div");
        row.className = "row";
        row.style.marginBottom = "2em";

        const leftCol = document.createElement("div");
        leftCol.className = "col-sm-3 text-start";
        leftCol.innerHTML = i === 0 ? `<h3 class="type-title">${type}</h3>` : "&nbsp;";

        const rightCol = document.createElement("div");
        rightCol.className = "col-sm-9";
        rightCol.innerHTML = `
          <div class="entry">
            <div class="title" style="font-weight: bold;">${e.title}</div>
            <div class="author" style="margin-top: 0.3em;">${e.authors}</div>
            ${(e.journal || e.year) ? `
              <div class="periodical" style="margin-top: 0.3em;">
                ${e.journal ? `<span style="font-style: italic;">${e.journal}</span>${e.year ? ", " + e.year : ""}` : (e.year || "")}
              </div>
            ` : ""}
            ${e.doi ? `<div class="doi" style="margin-top: 0.3em;"><a href="https://doi.org/${e.doi}" target="_blank">https://doi.org/${e.doi}</a></div>` : ""}
           <div class="links" style="margin-top: 0.3em;">
			  <a href="${e.uri}" class="btn btn-sm me-2" role="button" target="_blank">
				<i class="fas fa-landmark"></i> View on HAL
			  </a>
			  <a href="${e.pdf}" class="btn btn-sm me-2" role="button" target="_blank">
				<i class="fas fa-file-pdf"></i> Download PDF
			  </a>
			  ${e.seeAlso ? `
				<a href="${e.seeAlso}" class="btn btn-sm" role="button" target="_blank">
				  <i class="fas fa-code"></i> See online code
				</a>` : ""}
			</div>
          </div>
        `;

        row.appendChild(leftCol);
        row.appendChild(rightCol);
        container.appendChild(row);
      });
    });
  })
  .catch(err => {
    console.error("❌ Failed to load XML TEI from HAL:", err);
    document.getElementById("hal-publications-container").innerText = "⚠️ Failed to load publications.";
  });
</script>
