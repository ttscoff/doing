### 2.1.111

2026-04-25 02:14

#### FIXED

- Clock-only --back times that are later than the current time now resolve to the previous day, so `doing done --back 2:30pm` after midnight records yesterday afternoon instead of failing with a NilClass conversion error.

