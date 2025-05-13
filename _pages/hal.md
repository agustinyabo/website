---
layout: page
title: publications
description: in reversed chronological order
permalink: /hal/
nav: true
nav_order: 2
---

<div class="publications" id="hal-publications-container"></div>

<style>
.entry .btn {
  color: grey;
  border: 1px solid grey;
  padding: 3px 8px;
  transition: all 0.2s ease;
  font-size: 0.7rem;
  text-decoration: none;
  border-radius: 2px;
  display: inline-block;
  margin-right: 0.5em;
}
.entry .btn:hover {
  color: var(--global-theme-color, #0076df);
  border: 1px solid var(--global-theme-color, #0076df);
  text-decoration: none;
}
</style>

<script>
fetch("https://api.archives-ouvertes.fr/search/hal/?wt=json&rows=1000&sort=publicationDate_tdate desc&q=authIdHal_s:agustin-gabriel-yabo")
  .then(response => response.json())
  .then(data => {
    const container = document.getElementById("hal-publications-container");
    const docs = data.response.docs;

    const groupedByYear = {};
    docs.forEach(pub => {
      const match = pub.label_s.match(/\b(19|20)\d{2}\b/);
      const year = match ? match[0] : "n.d.";
      if (!groupedByYear[year]) groupedByYear[year] = [];
      groupedByYear[year].push(pub);
    });

    const sortedYears = Object.keys(groupedByYear).sort((a, b) => b.localeCompare(a));

    sortedYears.forEach(year => {
      groupedByYear[year].forEach((pub, index) => {

        const row = document.createElement("div");
        row.className = "row";
        row.style.marginBottom = "2em";

        // <hr> inside the row, spans entire width
        if (index === 0) {
          const hrCol = document.createElement("div");
          hrCol.className = "col-12";
          hrCol.innerHTML = "<hr>";
          row.appendChild(hrCol);
        }

        // Left column (indentation)
        const leftCol = document.createElement("div");
        leftCol.className = "col-sm-1 abbr";
        leftCol.innerHTML = "&nbsp;";

        // Center column (publication content)
        const centerCol = document.createElement("div");
        centerCol.className = "col-sm-9";

        // Right column (year)
        const rightCol = document.createElement("div");
        rightCol.className = "col-sm-1 text-end";
        rightCol.innerHTML = index === 0 ? `<h2 class="year">${year}</h2>` : "&nbsp;";

        // Parse publication label
        let label = pub.label_s;
        const parts = label.split(". ");
		const authorsRaw = parts[0] ? parts[0].trim() : "";
		const title = parts[1] ? parts[1].trim() : label;
		const rawJournal = parts[2] ? parts[2].trim() : "";

        // Journal detection or fallback to "Preprint"
        let journal = "Preprint";
        if (rawJournal) {
          const journalParts = rawJournal.split(",");
          const firstChunk = journalParts[0] ? journalParts[0].trim() : "";
          if (firstChunk && !/^\d{4}$/.test(firstChunk)) {
            journal = firstChunk;
          }
        }

        // Replace name variations
        const formattedAuthors = authorsRaw
          .replace(/Agustín Gabriel Yabo/g, "Agustín G. Yabo")
          .replace(/Agustín G Yabo/g, "Agustín G. Yabo")
          .replace(/Agustín G\.? Yabo/g, "Agustín G. Yabo")
          .replace(/Agustín G. Yabo/g, "<u>Agustín G. Yabo</u>");

        const pdfLink = `${pub.uri_s}/document`;

        centerCol.innerHTML = `
          <div class="entry">
            <div class="title" style="font-weight: bold;">${title}</div>
            <div class="author" style="margin-top: 0.3em;">${formattedAuthors}</div>
            <div class="periodical" style="margin-top: 0.3em;">
              <span style="font-style: italic;">${journal}</span>, ${year}
            </div>
            <div class="links" style="margin-top: 0.3em;">
              <a href="${pub.uri_s}" class="btn btn-sm me-2" role="button" target="_blank">View on HAL</a>
              <a href="${pdfLink}" class="btn btn-sm" role="button" target="_blank">Download PDF</a>
            </div>
          </div>
        `;

        row.appendChild(leftCol);
        row.appendChild(centerCol);
        row.appendChild(rightCol);
        container.appendChild(row);
      });
    });
  });
</script>
