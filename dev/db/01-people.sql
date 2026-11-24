-- The people Grouper's "people" source reads (dev/conf/subject.properties).
-- dev/load.py adds the people demo/groups.yaml names.
CREATE TABLE demo_person (
  subject_id text PRIMARY KEY,
  login_id text NOT NULL UNIQUE,
  name text NOT NULL,
  description text NOT NULL,
  search_text text NOT NULL,
  email text
);
