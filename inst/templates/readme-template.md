---
purl: false
---

# A Practical Guide to README Files for Research Data and Software

## What is a README?

A README is a short, accessible document that provides the essential context needed to understand, interpret, and reuse a research artifact. Depending on the project, that artifact may be a dataset, a piece of software, or both.

The primary purpose of a README is to answer the questions a future reader — or your future self — will have:

- What is this?
- Who created it?
- How should it be used?
- What additional information is needed to understand or reproduce the work?

A well-written README reduces ambiguity, improves reproducibility, supports long-term preservation, and makes research outputs easier to share and cite. It complements — but does not replace — discipline-specific metadata standards or formal software documentation. Where such standards exist, they should generally be preferred, with the README serving as an accessible overview and entry point.

------------------------------------------------------------------------

## General Best Practices

Regardless of whether you are documenting data or software, a README should:

- Be written for someone unfamiliar with the project.
- Be stored alongside the files it describes.
- Be written in plain text or Markdown.
- Use clear headings and consistent formatting.
- Use standardized date formats (ISO 8601; `YYYY-MM-DD`).
- Keep terminology consistent throughout the document.
- Describe logical collections of files rather than every file individually, where appropriate.
- Link to detailed documentation rather than duplicating extensive technical information.
- Be maintained alongside the project so that it remains synchronized with the research artifact.
- Include only the information necessary for a reader to understand, reuse, and cite the work.

------------------------------------------------------------------------

## Recommended README Structure

Not every project needs every section below. The following apply to any research artifact, regardless of whether it involves data, software, or both:

- **General Information** — identify the project, its purpose, authors, contacts, and basic metadata.
- **Contacts** — identify the individuals responsible for creating or maintaining the project.
- **Funding & Acknowledgements** — credit funding sources, contributors, and supporting organizations.
- **Citation** — explain how the work should be cited.
- **License** — describe licensing terms and conditions for reuse.
- **Related Resources** — link to related publications, repositories, datasets, or companion projects.
- **Version Information** — record the current version and, when appropriate, major revisions.

If your project includes software or code, also consider:

- **Project Overview** — a concise summary of the software, its purpose, and overall organization.
- **Installation** — how to install and configure the software.
- **System Requirements** — supported operating systems, hardware requirements, and runtime dependencies.
- **Software Dependencies** — required packages, libraries, modules, or external software.
- **Usage** — how to execute the software and what outputs users should expect.
- **Testing** — available tests and how they should be run.
- **Known Limitations** — known issues, caveats, or limitations.
- **Project Organization** — a summary of the directory structure and major software components.

If your project includes a dataset, also consider:

- **Data & File Overview** — the files included in the dataset and how they relate to one another.
- **Methodology** — how the data were collected, generated, or processed.
- **Data Provenance** — the origins of the data and relationships to other datasets.
- **Experimental Context** — collection dates, locations, instruments, calibration, and experimental conditions, when appropriate.
- **Quality Assurance** — validation, quality-control, or verification procedures.
- **Data Dictionary** — variables, units, codes, missing values, and other information needed to interpret the data.

------------------------------------------------------------------------

## Documenting Data and Software Separately

Many research projects include both data and software, and the structure above is meant to accommodate that: draw on the sections relevant to your project from the groups above rather than choosing a single identity for the whole document. When data and software are published as genuinely independent research products, however, consider giving each its own README, with cross-references between them, so that either one can be understood and reused on its own.

------------------------------------------------------------------------

## Inspiration

This guide draws on the recommendations developed by Cornell Data Services for documenting research data and software:

- <https://data.research.cornell.edu/data-management/sharing/readme/>
- <https://data.research.cornell.edu/data-management/sharing/writing-readmes-for-research-code-software/>

Rather than reproduce their guidance in full, this document summarizes the shared principles and proposes a unified structure suitable for most research projects. Consult the links above for the fuller treatment, additional examples, and downloadable templates.
