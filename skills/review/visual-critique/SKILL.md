---
name: visual-critique
description: Get a robust, noise-free 3-run majority-vote visual critique of 3D renders, joint positions, skeletal anatomy, or UI look-and-feel via the Gemini CLI, synthesizing a consensus report that eliminates LLM hallucinations. Use when you need to verify a 3D pose, spot broken anatomy/rotation bugs, or review design details before proceeding.
---

# Visual Critique

Get an independent, high-signal visual review of a 3D render, skeletal pose, or UI look-and-feel. 
To defeat single-run visual hallucinations and "noisy" LLM visual reasoning, this skill automates **majority-vote visual critique**: it runs the visual inspection **3 times in parallel** using a high-fidelity pro model (`gemini-2.5-pro`), then pipes the three raw outputs into a fast consensus engine (`gemini-2.5-flash`) to synthesize a single, noise-free, authoritative report containing only verified consensus findings.

## When to use

- After posing a joint or body part to verify its anatomical correctness, athletic quality, and balance.
- To detect subtle rotation coupling, local axis leakage, or coordinate space inversions in a 3D mesh.
- To review UI polish, alignment, margins, font weights, or design details.
- Whenever a single visual inspection feels "unstable" or flips back and forth.

## Process

### 1. Generate the render / screenshot
Save or copy the target render/image into the workspace (e.g., inside `public/` or `tmp/` so it is accessible to local tools and the `gemini` CLI).

### 2. Run the visual critique
Call the visual critique script, passing the image path and a specific focus or expectation:

```bash
skills/review/visual-critique/gemini-visual-critique.sh \
  --focus "Verify the knee flex (address knee line) and check if the pelvis looks squatted" \
  public/hackmotion/clubface-proof/fwd-check.png
```

- `--focus` instructs the model on what specific mechanics, joints, or design details to stress-test.
- The script will launch 3 parallel `gemini-2.5-pro` vision queries, collect their reviews, and pass them to `gemini-2.5-flash` to synthesize a consensus.

### 3. Act on the consensus
The final report only includes findings verified by at least 2 of the 3 runs. Use these to debug your math:
* **Check the Coordinate Order:** If the model reports a "broken/twisted spine" under turn, check if your rotation order is rotating the tilt axis.
* **Check Bone vs. Proxy Measurement:** If the model reports a visual posture match but the measured metric is off, calibrate the measurement engine using the actual 3D bone orientation rather than 2D/projected proxies.
