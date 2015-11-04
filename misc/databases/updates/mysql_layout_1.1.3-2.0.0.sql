DELIMITER //

CREATE FUNCTION prepare_wildcard(input text) RETURNS text DETERMINISTIC
BEGIN
    DECLARE escape_us   text;
    DECLARE escape_pc   text;
    DECLARE wildcard1   text;
    DECLARE unescape_ar text;
    DECLARE wildcard2   text;

    SET escape_us   = REPLACE(input, '_', '\\_');
    SET escape_pc   = REPLACE(escape_us, '%', '\\%');
    SET wildcard1   = REPLACE(escape_pc, '*', '{WILDCARD}');
    SET unescape_ar = REPLACE(wildcard1, '\\{WILDCARD}', '*');
    SET wildcard2   = REPLACE(unescape_ar, '{WILDCARD}', '%');

    RETURN wildcard2;
END; //

DELIMITER ;

ALTER TABLE requests ADD resource text NOT NULL DEFAULT '';
ALTER TABLE settings ADD locale text NOT NULL DEFAULT '';

UPDATE blacklist_filters SET rule = '(?:(?<!\\w)(?:\\.(?:ht(?:access|passwd|group))|(?:/etc/([./]*)(?:passwd|shadow|master\\.passwd))|(?:apache|httpd|lighttpd)\\.conf)\\b)', impact = 4, description = 'Finds sensible file names (Unix)' WHERE id = 12;
UPDATE blacklist_filters SET rule = '(?:(^(\\s*)\\||\\|(\\s*)$))' WHERE id = 104;
UPDATE blacklist_filters SET rule = '(?:(?<!\\w)(boot\\.ini|global\\.asa)\\b)', impact = 4, description = 'Finds sensible file names (Win)' WHERE id = 109;
UPDATE whitelist_filters SET description = 'Numeric (extended)' WHERE id = 2;

DELETE FROM tags_filters;
DELETE FROM tags;

INSERT INTO tags VALUES (1, 'xss');
INSERT INTO tags VALUES (2, 'win');
INSERT INTO tags VALUES (3, 'unix');
INSERT INTO tags VALUES (4, 'id');
INSERT INTO tags VALUES (5, 'lfi');
INSERT INTO tags VALUES (6, 'rfe');
INSERT INTO tags VALUES (7, 'sqli');
INSERT INTO tags VALUES (8, 'spam');
INSERT INTO tags VALUES (9, 'dos');
INSERT INTO tags VALUES (11, 'exec');
INSERT INTO tags VALUES (12, 'asm');
INSERT INTO tags VALUES (13, 'php');
INSERT INTO tags VALUES (14, 'perl');
INSERT INTO tags VALUES (15, 'python');

INSERT INTO tags_filters VALUES (1, 1);
INSERT INTO tags_filters VALUES (1, 2);
INSERT INTO tags_filters VALUES (1, 3);
INSERT INTO tags_filters VALUES (1, 4);
INSERT INTO tags_filters VALUES (1, 5);
INSERT INTO tags_filters VALUES (1, 6);
INSERT INTO tags_filters VALUES (1, 7);
INSERT INTO tags_filters VALUES (1, 8);
INSERT INTO tags_filters VALUES (1, 9);
INSERT INTO tags_filters VALUES (5, 10);
INSERT INTO tags_filters VALUES (4, 11);
INSERT INTO tags_filters VALUES (5, 11);
INSERT INTO tags_filters VALUES (3, 12);
INSERT INTO tags_filters VALUES (4, 12);
INSERT INTO tags_filters VALUES (5, 12);
INSERT INTO tags_filters VALUES (1, 13);
INSERT INTO tags_filters VALUES (1, 14);
INSERT INTO tags_filters VALUES (1, 15);
INSERT INTO tags_filters VALUES (1, 16);
INSERT INTO tags_filters VALUES (1, 17);
INSERT INTO tags_filters VALUES (1, 18);
INSERT INTO tags_filters VALUES (1, 19);
INSERT INTO tags_filters VALUES (1, 20);
INSERT INTO tags_filters VALUES (1, 21);
INSERT INTO tags_filters VALUES (1, 22);
INSERT INTO tags_filters VALUES (1, 23);
INSERT INTO tags_filters VALUES (1, 24);
INSERT INTO tags_filters VALUES (1, 25);
INSERT INTO tags_filters VALUES (1, 26);
INSERT INTO tags_filters VALUES (1, 27);
INSERT INTO tags_filters VALUES (1, 28);
INSERT INTO tags_filters VALUES (1, 29);
INSERT INTO tags_filters VALUES (1, 30);
INSERT INTO tags_filters VALUES (1, 31);
INSERT INTO tags_filters VALUES (1, 32);
INSERT INTO tags_filters VALUES (1, 33);
INSERT INTO tags_filters VALUES (1, 34);
INSERT INTO tags_filters VALUES (1, 35);
INSERT INTO tags_filters VALUES (7, 35);
INSERT INTO tags_filters VALUES (1, 37);
INSERT INTO tags_filters VALUES (1, 38);
INSERT INTO tags_filters VALUES (1, 39);
INSERT INTO tags_filters VALUES (6, 39);
INSERT INTO tags_filters VALUES (7, 40);
INSERT INTO tags_filters VALUES (7, 41);
INSERT INTO tags_filters VALUES (7, 42);
INSERT INTO tags_filters VALUES (7, 43);
INSERT INTO tags_filters VALUES (7, 44);
INSERT INTO tags_filters VALUES (7, 45);
INSERT INTO tags_filters VALUES (7, 46);
INSERT INTO tags_filters VALUES (7, 47);
INSERT INTO tags_filters VALUES (7, 48);
INSERT INTO tags_filters VALUES (7, 49);
INSERT INTO tags_filters VALUES (7, 50);
INSERT INTO tags_filters VALUES (7, 51);
INSERT INTO tags_filters VALUES (7, 52);
INSERT INTO tags_filters VALUES (7, 53);
INSERT INTO tags_filters VALUES (7, 54);
INSERT INTO tags_filters VALUES (7, 55);
INSERT INTO tags_filters VALUES (7, 56);
INSERT INTO tags_filters VALUES (7, 57);
INSERT INTO tags_filters VALUES (11, 58);
INSERT INTO tags_filters VALUES (13, 58);
INSERT INTO tags_filters VALUES (11, 59);
INSERT INTO tags_filters VALUES (13, 59);
INSERT INTO tags_filters VALUES (11, 60);
INSERT INTO tags_filters VALUES (13, 60);
INSERT INTO tags_filters VALUES (1, 61);
INSERT INTO tags_filters VALUES (6, 61);
INSERT INTO tags_filters VALUES (1, 62);
INSERT INTO tags_filters VALUES (8, 63);
INSERT INTO tags_filters VALUES (5, 64);
INSERT INTO tags_filters VALUES (1, 65);
INSERT INTO tags_filters VALUES (9, 65);
INSERT INTO tags_filters VALUES (1, 68);
INSERT INTO tags_filters VALUES (1, 69);
INSERT INTO tags_filters VALUES (7, 70);
INSERT INTO tags_filters VALUES (1, 71);
INSERT INTO tags_filters VALUES (7, 72);
INSERT INTO tags_filters VALUES (2, 73);
INSERT INTO tags_filters VALUES (5, 73);
INSERT INTO tags_filters VALUES (12, 75);
INSERT INTO tags_filters VALUES (7, 76);
INSERT INTO tags_filters VALUES (12, 77);
INSERT INTO tags_filters VALUES (1, 100);
INSERT INTO tags_filters VALUES (1, 101);
INSERT INTO tags_filters VALUES (3, 102);
INSERT INTO tags_filters VALUES (11, 102);
INSERT INTO tags_filters VALUES (1, 103);
INSERT INTO tags_filters VALUES (11, 104);
INSERT INTO tags_filters VALUES (14, 104);
INSERT INTO tags_filters VALUES (11, 105);
INSERT INTO tags_filters VALUES (11, 106);
INSERT INTO tags_filters VALUES (13, 106);
INSERT INTO tags_filters VALUES (11, 107);
INSERT INTO tags_filters VALUES (13, 107);
INSERT INTO tags_filters VALUES (8, 108);
INSERT INTO tags_filters VALUES (2, 109);
INSERT INTO tags_filters VALUES (4, 109);
INSERT INTO tags_filters VALUES (5, 109);
INSERT INTO tags_filters VALUES (11, 110);

CREATE TABLE integrity_rules (
    id          INTEGER UNSIGNED NOT NULL AUTO_INCREMENT primary key,
    profile_id  INTEGER UNSIGNED NOT NULL,
    caller      text NOT NULL,
    algorithm   text NOT NULL,
    hash        text NOT NULL,
    date        DATETIME,
    status      smallint NOT NULL,
    CONSTRAINT fk_integrity_rules1 FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
);

CREATE INDEX idx_integrity_rules1 ON whitelist_rules (profile_id);
CREATE INDEX idx_integrity_rules2 ON whitelist_rules (caller(20));
CREATE INDEX idx_integrity_rules3 ON whitelist_rules (algorithm(20));
CREATE INDEX idx_integrity_rules4 ON whitelist_rules (hash(20));
CREATE INDEX idx_integrity_rules5 ON whitelist_rules (date);
CREATE INDEX idx_integrity_rules6 ON whitelist_rules (status);

CREATE TABLE integrity_hashes (
    id          INTEGER UNSIGNED NOT NULL AUTO_INCREMENT primary key,
    request_id  INTEGER UNSIGNED NOT NULL,
    algorithm   text NOT NULL,
    hash        text NOT NULL,
    CONSTRAINT fk_integrity_hashes1 FOREIGN KEY (request_id) REFERENCES requests (id) ON DELETE CASCADE
);

CREATE INDEX idx_integrity_rules1 ON whitelist_rules (request_id);
CREATE INDEX idx_integrity_rules3 ON whitelist_rules (algorithm(20));
CREATE INDEX idx_integrity_rules4 ON whitelist_rules (hash(20));
