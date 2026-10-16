# Validation status

Development date: 2026-10-16 (Asia/Tokyo). No Cloud Run deployment, IAM changes, GitHub Pages settings changes or Pages publication performed.

| Check | Result |
| --- | --- |
| R package installation | PASS on Windows R 4.4.0 with Rtools: loadings 0.6.1, ellmer 0.5.0, httr2 1.3.0, nanonext 1.10.3, pinned mcptools 1.0.3.9000 |
| PCA MVP first | PASS before adding other methods: numeric comparison with official functions, truncation and invalid inputs |
| All five methods | PASS: local demo analysis and loading result comparison with official functions |
| HTTP server startup | PASS: child R process, validated PORT, /mcp endpoint |
| Official MCP client discovery | PASS: mcptools::mcp_tools, exactly three intended tools, no session/code execution tools |
| Official MCP client execution | PASS: PCA success, truncation, invalid input, four additional analysis methods |
| Demo artifacts | PASS: R-generated Iris input/output JSON and score/loading SVG plots |
| Static site | PASS: section, relative asset/link, viewport and endpoint placeholder checks; JavaScript syntax checked |
| Visual browser rendering / mobile | UNVERIFIED: no browser automation available; responsive CSS supplied |
| Docker build/runtime | PASS on GitHub Actions Linux: image build, nonroot container startup with PORT=8090 and HTTP MCP initialization. Docker not available locally. |
| Cloud Run container compatibility | Configuration reviewed against runtime contract: 0.0.0.0, PORT, exec CMD, concurrency 1; deployed runtime UNVERIFIED |
| Cloud Run external MCP client | UNVERIFIED: deployment requires explicit approval, project/image and authentication decision |
| ChatGPT / Claude Desktop / Claude Code | Official connection methods documented; manual client tests UNVERIFIED |
| GitHub Pages deployment | UNVERIFIED: manual workflow ready; publication/settings require explicit approval |

Initial installation emitted Windows locale startup warnings and a remotes tar extraction warning, but installation completed and exact pinned versions loaded successfully. These are separate from analysis warnings. Transitive CRAN versions are not fully locked; preserve production image digest for artifact reproducibility.
