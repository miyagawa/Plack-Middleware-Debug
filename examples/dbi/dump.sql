BEGIN TRANSACTION;
CREATE TABLE foo (id integer, foo text);
INSERT INTO "foo" VALUES(1,'bar');
INSERT INTO "foo" VALUES(2,'xxx');
COMMIT;
