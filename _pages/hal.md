---
layout: page
title: publications
description: grouped by type and ordered by year
permalink: /hal/
nav: true
nav_order: 2
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
  const entries = Array.from(xml.querySelectorAll("biblFull"));

  return entries.map(entry => {
    const titleNode = entry.querySelector("titleStmt > title");
    const title = titleNode ? titleNode.textContent.trim() : "";

    const rawAuthors = Array.from(entry.querySelectorAll("author")).map(a => {
      const pers = a.querySelector("persName");
      if (!pers) return "";
      const name = Array.from(pers.children).map(c => c.textContent.trim()).join(" ");
      return cleanName(name.trim());
    });
    let authors = deduplicateAuthors(rawAuthors).join(", ");

    const typeMap = {
      "Journal articles": "Journal articles",
      "Preprints, Working Papers, ...": "Preprints",
      "Conference papers": "Conference papers",
      "Book sections": "Book sections",
      "Books": "Books",
      "Theses": "PhD Thesis"
    };

    const rawTypeNode = entry.querySelector("classCode[scheme='halTypology']");
    const rawType = rawTypeNode ? rawTypeNode.textContent.trim() : "Other";
    const rawTypeN = rawTypeNode ? rawTypeNode.getAttribute("n") : "";

    const doiNode = entry.querySelector("idno[type='doi']");
    const doi = doiNode ? doiNode.textContent.trim() : "";

    let type = typeMap[rawType] || "Other";
    if (rawTypeN === "THESE") {
      type = "PhD Thesis";
    }
    if (type === "Conference papers") {
      type = doi ? "Conference Paper (with proceedings)" : "Talk (without proceedings)";
    }

    let year = "";
    const datePub = entry.querySelector("date[type='datePub']") || entry.querySelector("date");
    if (datePub) {
      const when = datePub.getAttribute("when");
      year = when ? when.slice(0, 4) : datePub.textContent.trim().slice(0, 4);
    }

    let journal = "";
    if (
      rawType === "Conference papers" ||
      type.startsWith("Conference") ||
      type.startsWith("Talk")
    ) {
      const confNameNode = entry.querySelector("meeting > title");
      const confName = confNameNode ? confNameNode.textContent.trim() : "Conference";
      const startNode = entry.querySelector("meeting > date[type='start']");
      const endNode = entry.querySelector("meeting > date[type='end']");
      const startDate = startNode ? startNode.textContent.trim() : "";
      const endDate = endNode ? endNode.textContent.trim() : "";
      const cityNode = entry.querySelector("meeting > settlement");
      const city = cityNode ? cityNode.textContent.trim() : "";
      const countryNode = entry.querySelector("meeting > country");
      const country = countryNode ? countryNode.textContent.trim() : "";
      journal = [confName, [city, country].filter(Boolean).join(", ")].filter(Boolean).join(", ");
      year = startDate ? startDate.slice(0, 4) : year;
    } else if (type === "PhD Thesis") {
      const institutionNode = entry.querySelector("monogr > authority[type='institution']");
      if (institutionNode) {
        const university = institutionNode.textContent.trim();
        journal = university;
      }
    } else {
      const publisherNode = entry.querySelector("monogr > imprint > publisher") || entry.querySelector("publicationStmt > publisher");
      const publisher = publisherNode ? publisherNode.textContent.trim() : "";
      const monogrTitleNode = entry.querySelector("monogr > title");
      const monogrTitle = monogrTitleNode ? monogrTitleNode.textContent.trim() : "";

      if (type === "Books") {
        journal = publisher || "Book";
      } else if (type === "Book sections") {
        journal = monogrTitle || publisher;
      } else if (monogrTitle) {
        journal = monogrTitle;
      } else if (publisher) {
        journal = publisher;
      }
    }

    if (journal.endsWith(" ")) journal = journal.trimEnd();

    const halIdNode = entry.querySelector("idno[type='halId']");
    const halId = halIdNode ? halIdNode.textContent.trim() : "";
    const uriNode = entry.querySelector("idno[type='halUri']");
    const uri = uriNode ? uriNode.textContent.trim() : `https://hal.science/${halId}`;
    const pdfNode = entry.querySelector("ref[type='file'][subtype='author']");
    const pdf = pdfNode ? pdfNode.getAttribute("target") : `${uri}/document`;

    return { title, authors, journal, year, uri, pdf, type, doi };
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
      "Preprints",
      "Journal articles",
      "Conference Paper (with proceedings)",
      "Talk (without proceedings)",
      "Books",
      "Book sections",
      "PhD Thesis",
      "Other"
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
              <a href="${e.uri}" class="btn btn-sm me-2" role="button" target="_blank">View on HAL</a>
              <a href="${e.pdf}" class="btn btn-sm" role="button" target="_blank">Download PDF</a>
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
