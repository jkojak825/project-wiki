---
title: Pushing Config Changes to the Project Wiki
tags:
  - Push
prerequisites:
  - ""
steps:
  - ""
verification: >-
  g﻿it pull first to ensure that everything in production that is working is
  correct before you make any changes to the configs. 


  git add docs/admin/config.yml

  git commit -m "Clean YAML config formatting"

  git push origin main
notes: "- "
---
