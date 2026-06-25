---
spine-dimension: C3
owner: aid-researcher-analyst
---
# Analysis Conventions

## Conventions

- Python 3.11+; all data processing modules use type annotations.
- Column naming: snake_case; boolean columns prefixed `is_` or `has_`.
- New pipeline stages are registered in `src/pipeline/registry.py` under a unique
  stage key matching the module filename (without `.py`).
- All SQL migrations follow the naming pattern `YYYYMMDD_<description>.sql` and
  must be idempotent.
- Feature engineering functions must have unit tests covering null-input and
  boundary conditions.
- Model evaluation reports are written to `reports/<model_name>/<run_date>/`.
