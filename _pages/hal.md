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
  const parser = new DOMParser();
  const xml = parser.parseFromString(xmlText, "text/xml");
  const NS = "http://www.tei-c.org/ns/1.0";
  const entries = Array.from(xml.getElementsByTagNameNS(NS, "biblFull"));

  return entries.map(entry => {
    const titleNode = entry.getElementsByTagNameNS(NS, "title")[0];
    const title = titleNode ? titleNode.textContent.trim() : "";

    const rawAuthors = Array.from(entry.getElementsByTagNameNS(NS, "author")).map(a => {
      const pers = a.getElementsByTagNameNS(NS, "persName")[0];
      if (!pers) return "";
      const name = Array.from(pers.children).map(c => c.textContent.trim()).join(" ");
      return cleanName(name.trim());
    });
    const authors = deduplicateAuthors(rawAuthors).join(", ");

    const idnos = Array.from(entry.getElementsByTagNameNS(NS, "idno"));
    const getIdno = type => {
      const node = idnos.find(el => el.getAttribute("type") === type);
      return node ? node.textContent.trim() : "";
    };

    const doi = getIdno("doi");
    const seeAlsoNode = entry.querySelector('ref[type="seeAlso"]');
	const seeAlso = seeAlsoNode ? seeAlsoNode.getAttribute("target") : "";
    const halId = getIdno("halId");
    const uri = getIdno("halUri") || `https://hal.science/${halId}`;

    const pdfNode = entry.querySelector("ref[type='file'][subtype='author']");
    const pdf = pdfNode ? pdfNode.getAttribute("target") : `${uri}/document`;

    const rawTypeNode = entry.querySelector("classCode[scheme='halTypology']");
    const rawType = rawTypeNode ? rawTypeNode.textContent.trim() : "other";
    const rawTypeN = rawTypeNode ? rawTypeNode.getAttribute("n") : "";

    const typeMap = {
      "Journal articles": "journal articles",
      "Preprints, Working Papers, ...": "preprints",
      "Conference papers": "conference papers",
      "Book sections": "book sections",
      "Books": "books",
      "Theses": "phd thesis"
    };

    let type = typeMap[rawType] || "Other";
    if (rawTypeN === "THESE") type = "phd thesis";

    if (rawType === "Conference papers") {
      const procNote = entry.querySelector("note[type='proceedings']");
      const inProceedings = procNote && procNote.getAttribute("n") === "1";
      type = inProceedings ? "conference paper (with proceedings)" : "talk (without proceedings)";
    }

    let year = "";
    const dateNode = entry.querySelector("date[type='datePub']") || entry.querySelector("date");
    if (dateNode) {
      const when = dateNode.getAttribute("when");
      year = when ? when.slice(0, 4) : dateNode.textContent.trim().slice(0, 4);
    }

    let journal = "";
    if (
      rawType === "Conference papers" ||
      type.startsWith("Conference") ||
      type.startsWith("Talk")
    ) {
      const confName = entry.querySelector("meeting > title")?.textContent.trim() || "";
      const city = entry.querySelector("meeting > settlement")?.textContent.trim() || "";
      const country = entry.querySelector("meeting > country")?.textContent.trim() || "";
      journal = [confName, [city, country].filter(Boolean).join(", ")].filter(Boolean).join(", ");
      const start = entry.querySelector("meeting > date[type='start']")?.textContent.trim();
      year = start ? start.slice(0, 4) : year;
    } else if (type === "PhD Thesis") {
      const inst = entry.querySelector("monogr > authority[type='institution']");
      journal = inst ? inst.textContent.trim() : "";
    } else {
      const pub = entry.querySelector("monogr > imprint > publisher") ||
                  entry.querySelector("publicationStmt > publisher");
      const title = entry.querySelector("monogr > title");
      journal = title?.textContent.trim() || pub?.textContent.trim() || "";
    }

    return { title, authors, journal, year, uri, pdf, type, doi, seeAlso };
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
