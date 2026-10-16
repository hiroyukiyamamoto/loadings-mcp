# Validation status

Development/publication date: 2026-10-16 (Asia/Tokyo). GitHub Pages is now published under the subsequent explicit publication request. Cloud Run deployment and IAM changes remain pending approval. See [publication status](DEPLOYMENT.md).

Final implementation commit `5b181fd` passed both Linux R and Docker jobs in [GitHub Actions run 38888286171](https://github.com/hiroyukiyamamoto/loadings-mcp/actions/runs/38888286171). Later validation-documentation-only commits do not change the tested implementation.

| Check | Result |
| --- | --- |
| R package installation | PASS on Windows R 4.4.0 with Rtools and Linux R 4.5.2 CI: loadings 0.6.1, ellmer 0.5.0, httr2 1.3.0, pinned mcptools 1.0.3.9000. Windows nanonext 1.10.3. |
| PCA MVP first | PASS before adding other methods: numeric comparison with official functions, truncation and invalid inputs |
| All five methods | PASS: local demo analysis and loading result comparison with official functions |
| HTTP server startup | PASS: child R process, validated PORT, /mcp endpoint |
| Official MCP client discovery | PASS: mcptools::mcp_tools, exactly three intended tools, no session/code execution tools |
| Official MCP client execution | PASS: PCA success, truncation, invalid input, four additional analysis methods |
| Demo artifacts | PASS: R-generated Iris input/output JSON and score/loading SVG plots |
| Static site | PASS: section, relative asset/link, viewport and endpoint placeholder checks; JavaScript syntax checked |
| Visual browser rendering / mobile | PASS on live GitHub Pages using headless Microsoft Edge at desktop 1440×1000 and mobile 390×844: screenshots inspected, no horizontal overflow, images load and anchors resolve |
| Docker build/runtime | PASS on GitHub Actions Linux: image build, nonroot container startup with PORT=8090 and HTTP MCP initialization. Docker not available locally. |
| Cloud Run container compatibility | Configuration reviewed against runtime contract: 0.0.0.0, PORT, exec CMD, concurrency 1; deployed runtime UNVERIFIED |
| Cloud Run external MCP client | UNVERIFIED: deployment requires explicit approval, project/image and authentication decision |
| ChatGPT / Claude Desktop / Claude Code | Official connection methods documented; manual client tests UNVERIFIED |
| GitHub Pages deployment | PASS: switched source to GitHub Actions under publication authorization; run 38910609509 succeeded; live HTML/assets/config/plots/demo JSON/documentation return HTTP 200 |

All R analysis/HTTP checks, artifact generation and static-site checks also passed in Linux CI. Initial CI found missing libuv/zlib development headers in the image and a GitHub API credential problem in the R runner. These were fixed by adding system libraries, verifying installed mcptools during image construction, and downloading the pinned public source archive directly. Both final jobs passed after these corrections.

During the initial implementation, legacy Pages runs were cancelled because publication was not yet approved. Under the subsequent publication request, the source was changed to GitHub Actions and the site was successfully published. This supersedes the initial unpublished state; manual `pages.yml` dispatch now controls publication.

Initial installation emitted Windows locale startup warnings and a remotes tar extraction warning, but installation completed and exact pinned versions loaded successfully. These are separate from analysis warnings. Transitive CRAN versions are not fully locked; preserve production image digest for artifact reproducibility.
