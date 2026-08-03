# Requests for Comments

Use `docs/templates/RFC-Template.md`.

`RFC-0001` is allocated to the storage-contract and logical-data-model
composition Draft. The next unallocated numeric identifier is `RFC-0002`.

[`RFC-0001-CCD-01`](RFC-0001-controlled-correction-delta.md) is its Draft
controlled-correction companion. It consumes no additional RFC number and has
no independent approval or source authority.

`Tools/Scripts/check_rfc_register.py` validates file-backed metadata, the
primary register, companion relationships, numeric allocation and correction
crosswalks. Passing that structural check never accepts an RFC, makes a
correction effective or grants source authority. Named ownership and signatory
enforcement remain external governance responsibilities. Until a
machine-readable approval schema is governed, the validator fails closed on
every status other than `Draft`.

| ID | Status | Proposal |
|---|---|---|
| [RFC-0001](RFC-0001-storage-contract-and-logical-data-model-composition.md) | Draft | Storage contract and logical data-model composition |
