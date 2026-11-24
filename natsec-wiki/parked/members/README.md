# Parked: member lenses

The member lenses for Rep. Jason Crow (CO-06) and Rep. Sara Jacobs (CA-51) were taken off the site on November 24, 2026, at the owner's request (D-017 in `../../../DECISIONS.md`). Nothing here is rendered or validated while it sits in this folder.

| File | Where it goes to restore it |
|---|---|
| `crow.yml`, `jacobs.yml` | `data/members/` |
| `_lens.qmd`, `index.qmd` | `members/` |

To bring the lenses back:

1. Move the files back, from the `natsec-wiki` folder:
   `git mv parked/members/crow.yml parked/members/jacobs.yml data/members/` (create `data/members/` first), then `git mv parked/members/_lens.qmd parked/members/index.qmd members/` (create `members/` first).
2. In `_quarto.yml`, add `"members/*.qmd"` back to `project: render:` and restore the Members navbar menu (it is in git history before D-017).
3. Run `Rscript R/deploy.R check`. `R/build_pages.R` regenerates `members/<slug>.qmd`, adds the "Member lenses" line to statute pages, and checks every statute id the lenses cite.
4. Recheck the items the lenses flagged as unverified, and the members' committee assignments for the current Congress, before publishing. The links the old site added from the home page, the Sources page, the About page, and the civilian harm unit were removed and would need to be added back by hand.
