# Validation status

Cost-control review, 2026-10-17: no new Cloud Run deployment, API activation, budget or IAM change was performed. The new spend-cap gate tests pass locally and all eight packaged-demo benchmarks succeed (Windows RSS sampling, not Cloud Run sizing). `scripts/deploy.sh` now requires a dedicated project and settled configured cap <= JPY 400; its 512 MiB/30s private-runtime candidate remains unverified. Budget API access returns 403 SERVICE_DISABLED, so account-level cap creation/read-back and costs remain unverified. See [operations review](OPERATIONS.md); this supersedes the old shared-project rollout plan. R analysis/transport code is unchanged, and existing successful implementation checks remain valid.

Development/publication date: 2026-10-16 (Asia/Tokyo). GitHub Pages is now published under the subsequent explicit publication request. Cloud Run deployment and IAM changes remain pending approval. See [publication status](DEPLOYMENT.md).

Final implementation commit `5b181fd` passed both Linux R and Docker jobs in [GitHub Actions run 38888286171](https://github.com/hiroyukiyamamoto/loadings-mcp/actions/runs/38888286171). Later validation-documentation-only commits do not change the tested implementation.

The current metabolome/multiset extension `e0a9279` also passed both jobs in [run 38914299181](https://github.com/hiroyukiyamamoto/loadings-mcp/actions/runs/38914299181), including all three new multiset methods and four-tool HTTP discovery/execution. [Pages run 38914326566](https://github.com/hiroyukiyamamoto/loadings-mcp/actions/runs/38914326566) published the simpler site. Live desktop/mobile browser checks passed again with all three metabolome figures; the fasting/whhl JSON files, figures and updated API document returned HTTP 200.

| Check | Result |
| --- | --- |
| R package installation | PASS on Windows R 4.4.0 with Rtools and Linux R 4.5.2 CI: loadings 0.6.1, ellmer 0.5.0, httr2 1.3.0, pinned mcptools 1.0.3.9000. Windows nanonext 1.10.3. |
| PCA MVP first | PASS before adding other methods: numeric comparison with official functions, truncation and invalid inputs |
| Single-dataset methods | PASS: all five methods on full fasting metabolome data, including official loading-result comparison and nonfinite-value handling |
| HTTP server startup | PASS: child R process, validated PORT, /mcp endpoint |
| Multiset methods | PASS on Windows and Linux CI: multiset PLS, multiset PLS-ROG and unsupervised multiset PLS on full matched whhl blocks; direct official loading-result comparison including the final tissue block |
| Official MCP client discovery | PASS on Windows and Linux CI: mcptools::mcp_tools, exactly four intended tools, no session/code execution tools |
| Official MCP client execution | PASS on Windows and Linux CI: fasting PCA, truncation, invalid input, four single-dataset models, whhl demo and all three multiset models |
| Demo artifacts | PASS: full packaged fasting input/PCA output, 282-metabolite loading plot, sample score plot, four-tissue whhl multiset result and score panels |
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
