---
spine-dimension: C9
owner: aid-researcher-architecture
---
# Model Cards

## Churn Prediction Model

Predicts probability that a user_profile will downgrade or cancel within 30 days.
Input: feature vectors derived from the past 90 days of events for that user.
Output: float in [0,1]; threshold 0.5 triggers a retention campaign.

## Purchase Propensity Model

Predicts probability that a free user will upgrade to pro within 7 days.
Input: feature vectors derived from the past 14 days of events.
Output: float in [0,1]; used for targeted upgrade offers.
