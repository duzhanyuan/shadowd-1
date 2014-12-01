-- Tables

CREATE TABLE tags (
	id		SERIAL primary key,
	tag		text NOT NULL
);

CREATE UNIQUE INDEX ON tags (tag);

CREATE TABLE blacklist_filters (
	id			SERIAL primary key,
	rule		text NOT NULL,
	impact		integer NOT NULL,
	description	text
);

CREATE INDEX ON blacklist_filters (rule);
CREATE INDEX ON blacklist_filters (impact);

CREATE TABLE tags_filters (
	tag_id		integer NOT NULL,
	filter_id	integer NOT NULL,
	FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE,
	FOREIGN KEY (filter_id) REFERENCES blacklist_filters (id) ON DELETE CASCADE,
	PRIMARY KEY (tag_id, filter_id)
);

CREATE INDEX ON tags_filters (tag_id);
CREATE INDEX ON tags_filters (filter_id);

CREATE TABLE profiles (
	id					SERIAL primary key,
	date				timestamp NOT NULL DEFAULT date_trunc('seconds', now()::timestamp),
	server_ip			text NOT NULL,
	name				text NOT NULL,
	hmac_key			text NOT NULL,
	learning_enabled	smallint NOT NULL,
	whitelist_enabled	smallint NOT NULL,
	blacklist_enabled	smallint NOT NULL,
	threshold			int NOT NULL
);

CREATE INDEX ON profiles (server_ip);

CREATE TABLE requests (
	id			SERIAL primary key,
	profile_id	int NOT NULL,
	caller		text NOT NULL,
	learning	smallint NOT NULL,
	client_ip	text NOT NULL,
	date		timestamp NOT NULL DEFAULT date_trunc('seconds', now()::timestamp),
	FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
);

CREATE INDEX ON requests (profile_id);
CREATE INDEX ON requests (caller);
CREATE INDEX ON requests (learning);
CREATE INDEX ON requests (client_ip);
CREATE INDEX ON requests (date);

CREATE TABLE parameters (
	id				SERIAL primary key,
	request_id		int NOT NULL,
	path			text NOT NULL,
	value			text NOT NULL,
	total_rules		int NOT NULL,
	critical_impact	smallint NOT NULL,
	threat			smallint NOT NULL,
	FOREIGN KEY (request_id) REFERENCES requests (id) ON DELETE CASCADE
);

CREATE INDEX ON parameters (request_id);
CREATE INDEX ON parameters (total_rules);
CREATE INDEX ON parameters (critical_impact);
CREATE INDEX ON parameters (threat);

CREATE TABLE blacklist_parameters (
	filter_id		int NOT NULL,
	parameter_id	int NOT NULL,
	FOREIGN KEY (filter_id) REFERENCES blacklist_filters (id) ON DELETE CASCADE,
	FOREIGN KEY (parameter_id) REFERENCES parameters (id) ON DELETE CASCADE,
	PRIMARY KEY (filter_id, parameter_id)
);

CREATE INDEX ON blacklist_parameters (filter_id);
CREATE INDEX ON blacklist_parameters (parameter_id);

CREATE TABLE whitelist_filters (
	id			SERIAL primary key,
	rule		text NOT NULL,
	impact		integer NOT NULL,
	description	text
);

CREATE INDEX ON whitelist_filters (rule);
CREATE INDEX ON whitelist_filters (impact);

CREATE TABLE whitelist_rules (
	id			SERIAL primary key,
	profile_id	integer NOT NULL,
	path		text NOT NULL,
	caller		text NOT NULL,
	min_length	integer NOT NULL,
	max_length	integer NOT NULL,
	filter_id	integer NOT NULL,
	date		timestamp NOT NULL DEFAULT date_trunc('seconds', now()::timestamp),
	status		smallint NOT NULL,
	FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE,
	FOREIGN KEY (filter_id) REFERENCES whitelist_filters (id) ON DELETE CASCADE
);

CREATE INDEX ON whitelist_rules (profile_id);
CREATE INDEX ON whitelist_rules (path);
CREATE INDEX ON whitelist_rules (caller);
CREATE INDEX ON whitelist_rules (min_length);
CREATE INDEX ON whitelist_rules (max_length);
CREATE INDEX ON whitelist_rules (filter_id);
CREATE INDEX ON whitelist_rules (date);
CREATE INDEX ON whitelist_rules (status);

CREATE TABLE whitelist_parameters (
	rule_id			int NOT NULL,
	parameter_id	int NOT NULL,
	FOREIGN KEY (rule_id) REFERENCES whitelist_rules (id) ON DELETE CASCADE,
	FOREIGN KEY (parameter_id) REFERENCES parameters (id) ON DELETE CASCADE,
	PRIMARY KEY (rule_id, parameter_id)
);

CREATE INDEX ON whitelist_parameters (rule_id);
CREATE INDEX ON whitelist_parameters (parameter_id);

-- Tables UI

CREATE TABLE users (
	id				SERIAL primary key,
	username		text NOT NULL,
	password		text NOT NULL,
	email			text NOT NULL,
	role			smallint NOT NULL,
	change_password	boolean,
	date			timestamp NOT NULL DEFAULT date_trunc('seconds', now()::timestamp)
);

CREATE UNIQUE INDEX ON users (username);

CREATE TABLE settings (
	id			SERIAL primary key,
	page_limit	integer NOT NULL,
	sort_order	smallint NOT NULL,
	theme		text NOT NULL,
	open_filter	boolean,
	user_id		integer NOT NULL,
	FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- Data

INSERT INTO blacklist_filters VALUES (1, '(?:"[^"]*[^-]?>)|(?:[^\w\s]\s*\/>)|(?:>")', 4, 'Finds html breaking injections including whitespace attacks');
INSERT INTO blacklist_filters VALUES (2, '(?:"+.*[<=]\s*"[^"]+")|(?:"\s*\w+\s*=)|(?:>\w=\/)|(?:#.+\)["\s]*>)|(?:"\s*(?:src|style|on\w+)\s*=\s*")|(?:[^"]?"[,;\s]+\w*[\[\(])', 4, 'Finds attribute breaking injections including whitespace attacks');
INSERT INTO blacklist_filters VALUES (3, '(?:^>[\w\s]*<\/?\w{2,}>)', 2, 'Finds unquoted attribute breaking injections');
INSERT INTO blacklist_filters VALUES (4, '(?:[+\/]\s*name[\W\d]*[)+])|(?:;\W*url\s*=)|(?:[^\w\s\/?:>]\s*(?:location|referrer|name)\s*[^\/\w\s-])', 5, 'Detects url-, name-, JSON, and referrer-contained payload attacks');
INSERT INTO blacklist_filters VALUES (5, '(?:\W\s*hash\s*[^\w\s-])|(?:\w+=\W*[^,]*,[^\s(]\s*\()|(?:\?"[^\s"]":)|(?:(?<!\/)__[a-z]+__)|(?:(?:^|[\s)\]\}])(?:s|g)etter\s*=)', 5, 'Detects hash-contained xss payload attacks, setter usage and property overloading');
INSERT INTO blacklist_filters VALUES (6, '(?:with\s*\(\s*.+\s*\)\s*\w+\s*\()|(?:(?:do|while|for)\s*\([^)]*\)\s*\{)|(?:\/[\w\s]*\[\W*\w)', 5, 'Detects self contained xss via with(), common loops and regex to string conversion');
INSERT INTO blacklist_filters VALUES (7, '(?:[=(].+\?.+:)|(?:with\([^)]*\)\))|(?:\.\s*source\W)', 5, 'Detects JavaScript with(), ternary operators and XML predicate attacks');
INSERT INTO blacklist_filters VALUES (8, '(?:\/\w*\s*\)\s*\()|(?:\([\w\s]+\([\w\s]+\)[\w\s]+\))|(?:(?<!(?:mozilla\/\d\.\d\s))\([^)[]+\[[^\]]+\][^)]*\))|(?:[^\s!][{([][^({[]+[{([][^}\])]+[}\])][\s+",\d]*[}\])])|(?:"\)?\]\W*\[)|(?:=\s*[^\s:;]+\s*[{([][^}\])]+[}\])];)', 5, 'Detects self-executing JavaScript functions');
INSERT INTO blacklist_filters VALUES (9, '(?:\\u00[a-f0-9]{2})|(?:\\x0*[a-f0-9]{2})|(?:\\\d{2,3})', 2, 'Detects the IE octal, hex and unicode entities');
INSERT INTO blacklist_filters VALUES (10, '(?:(?:\/|\\)?\.+(\/|\\)(?:\.+)?)|(?:\w+\.exe\??\s)|(?:;\s*\w+\s*\/[\w*-]+\/)|(?:\d\.\dx\|)|(?:%(?:c0\.|af\.|5c\.))|(?:\/(?:%2e){2})', 5, 'Detects basic directory traversal');
INSERT INTO blacklist_filters VALUES (11, '(?:%c0%ae\/)|(?:(?:\/|\\)(home|conf|usr|etc|proc|opt|s?bin|local|dev|tmp|kern|[br]oot|sys|system|windows|winnt|program|%[a-z_-]{3,}%)(?:\/|\\))|(?:(?:\/|\\)inetpub|localstart\.asp|boot\.ini)', 5, 'Detects specific directory and path traversal');
INSERT INTO blacklist_filters VALUES (12, '(?:etc\/\W*passwd)', 5, 'Detects etc/passwd inclusion attempts');
INSERT INTO blacklist_filters VALUES (13, '(?:%u(?:ff|00|e\d)\w\w)|(?:(?:%(?:e\w|c[^3\W]|))(?:%\w\w)(?:%\w\w)?)', 3, 'Detects halfwidth/fullwidth encoded unicode HTML breaking attempts');
INSERT INTO blacklist_filters VALUES (14, '(?:#@~\^\w+)|(?:\w+script:|@import[^\w]|;base64|base64,)|(?:\w+\s*\([\w\s]+,[\w\s]+,[\w\s]+,[\w\s]+,[\w\s]+,[\w\s]+\))', 5, 'Detects possible includes, VBSCript/JScript encodeed and packed functions');
INSERT INTO blacklist_filters VALUES (15, '([^*:\s\w,.\/?+-]\s*)?(?<![a-z]\s)(?<![a-z\/_@\-\|])(\s*return\s*)?(?:create(?:element|attribute|textnode)|[a-z]+events?|setattribute|getelement\w+|appendchild|createrange|createcontextualfragment|removenode|parentnode|decodeuricomponent|\wettimeout|(?:ms)?setimmediate|option|useragent)(?(1)[^\w%"]|(?:\s*[^@\s\w%",.+\-]))', 6, 'Detects JavaScript DOM/miscellaneous properties and methods');
INSERT INTO blacklist_filters VALUES (16, '([^*\s\w,.\/?+-]\s*)?(?<![a-mo-z]\s)(?<![a-z\/_@])(\s*return\s*)?(?:alert|inputbox|showmod(?:al|eless)dialog|showhelp|infinity|isnan|isnull|iterator|msgbox|executeglobal|expression|prompt|write(?:ln)?|confirm|dialog|urn|(?:un)?eval|exec|execscript|tostring|status|execute|window|unescape|navigate|jquery|getscript|extend|prototype)(?(1)[^\w%"]|(?:\s*[^@\s\w%",.:\/+\-]))', 5, 'Detects possible includes and typical script methods');
INSERT INTO blacklist_filters VALUES (17, '([^*:\s\w,.\/?+-]\s*)?(?<![a-z]\s)(?<![a-z\/_@])(\s*return\s*)?(?:hash|name|href|navigateandfind|source|pathname|close|constructor|port|protocol|assign|replace|back|forward|document|ownerdocument|window|top|this|self|parent|frames|_?content|date|cookie|innerhtml|innertext|csstext+?|outerhtml|print|moveby|resizeto|createstylesheet|stylesheets)(?(1)[^\w%"]|(?:\s*[^@\/\s\w%.+\-]))', 4, 'Detects JavaScript object properties and methods');
INSERT INTO blacklist_filters VALUES (18, '([^*:\s\w,.\/?+-]\s*)?(?<![a-z]\s)(?<![a-z\/_@\-\|])(\s*return\s*)?(?:join|pop|push|reverse|reduce|concat|map|shift|sp?lice|sort|unshift)(?(1)[^\w%"]|(?:\s*[^@\s\w%,.+\-]))', 4, 'Detects JavaScript array properties and methods');
INSERT INTO blacklist_filters VALUES (19, '([^*:\s\w,.\/?+-]\s*)?(?<![a-z]\s)(?<![a-z\/_@\-\|])(\s*return\s*)?(?:set|atob|btoa|charat|charcodeat|charset|concat|crypto|frames|fromcharcode|indexof|lastindexof|match|navigator|toolbar|menubar|replace|regexp|slice|split|substr|substring|escape|\w+codeuri\w*)(?(1)[^\w%"]|(?:\s*[^@\s\w%,.+\-]))', 4, 'Detects JavaScript string properties and methods');
INSERT INTO blacklist_filters VALUES (20, '(?:\)\s*\[)|([^*":\s\w,.\/?+-]\s*)?(?<![a-z]\s)(?<![a-z_@\|])(\s*return\s*)?(?:globalstorage|sessionstorage|postmessage|callee|constructor|content|domain|prototype|try|catch|top|call|apply|url|function|object|array|string|math|if|for\s*(?:each)?|elseif|case|switch|regex|boolean|location|(?:ms)?setimmediate|settimeout|setinterval|void|setexpression|namespace|while)(?(1)[^\w%"]|(?:\s*[^@\s\w%".+\-\/]))', 4, 'Detects JavaScript language constructs');
INSERT INTO blacklist_filters VALUES (21, '(?:,\s*(?:alert|showmodaldialog|eval)\s*,)|(?::\s*eval\s*[^\s])|([^:\s\w,.\/?+-]\s*)?(?<![a-z\/_@])(\s*return\s*)?(?:(?:document\s*\.)?(?:.+\/)?(?:alert|eval|msgbox|showmod(?:al|eless)dialog|showhelp|prompt|write(?:ln)?|confirm|dialog|open))\s*(?:[^.a-z\s\-]|(?:\s*[^\s\w,.@\/+-]))|(?:java[\s\/]*\.[\s\/]*lang)|(?:\w\s*=\s*new\s+\w+)|(?:&\s*\w+\s*\)[^,])|(?:\+[\W\d]*new\s+\w+[\W\d]*\+)|(?:document\.\w)', 3, 'Detects very basic XSS probings');
INSERT INTO blacklist_filters VALUES (22, '(?:=\s*(?:top|this|window|content|self|frames|_content))|(?:\/\s*[gimx]*\s*[)}])|(?:[^\s]\s*=\s*script)|(?:\.\s*constructor)|(?:default\s+xml\s+namespace\s*=)|(?:\/\s*\+[^+]+\s*\+\s*\/)', 5, 'Detects advanced XSS probings via Script(), RexExp, constructors and XML namespaces');
INSERT INTO blacklist_filters VALUES (23, '(?:\.\s*\w+\W*=)|(?:\W\s*(?:location|document)\s*\W[^({[;]+[({[;])|(?:\(\w+\?[:\w]+\))|(?:\w{2,}\s*=\s*\d+[^&\w]\w+)|(?:\]\s*\(\s*\w+)', 5, 'Detects JavaScript location/document property access and window access obfuscation');
INSERT INTO blacklist_filters VALUES (24, '(?:[".]script\s*\()|(?:\$\$?\s*\(\s*[\w"])|(?:\/[\w\s]+\/\.)|(?:=\s*\/\w+\/\s*\.)|(?:(?:this|window|top|parent|frames|self|content)\[\s*[(,"]*\s*[\w\$])|(?:,\s*new\s+\w+\s*[,;)])', 5, 'Detects basic obfuscated JavaScript script injections');
INSERT INTO blacklist_filters VALUES (25, '(?:=\s*[$\w]\s*[\(\[])|(?:\(\s*(?:this|top|window|self|parent|_?content)\s*\))|(?:src\s*=s*(?:\w+:|\/\/))|(?:\w+\[("\w+"|\w+\|\|))|(?:[\d\W]\|\|[\d\W]|\W=\w+,)|(?:\/\s*\+\s*[a-z"])|(?:=\s*\$[^([]*\()|(?:=\s*\(\s*")', 5, 'Detects obfuscated JavaScript script injections');
INSERT INTO blacklist_filters VALUES (26, '(?:[^:\s\w]+\s*[^\w\/](href|protocol|host|hostname|pathname|hash|port|cookie)[^\w])', 4, 'Detects JavaScript cookie stealing and redirection attempts');
INSERT INTO blacklist_filters VALUES (27, '(?:(?:vbs|vbscript|data):.*[,+])|(?:\w+\s*=\W*(?!https?)\w+:)|(jar:\w+:)|(=\s*"?\s*vbs(?:ript)?:)|(language\s*=\s?"?\s*vbs(?:ript)?)|on\w+\s*=\*\w+\-"?', 5, 'Detects data: URL injections, VBS injections and common URI schemes');
INSERT INTO blacklist_filters VALUES (28, '(?:firefoxurl:\w+\|)|(?:(?:file|res|telnet|nntp|news|mailto|chrome)\s*:\s*[%&#xu\/]+)|(wyciwyg|firefoxurl\s*:\s*\/\s*\/)', 5, 'Detects IE firefoxurl injections, cache poisoning attempts and local file inclusion/execution');
INSERT INTO blacklist_filters VALUES (29, '(?:binding\s?=|moz-binding|behavior\s?=)|(?:[\s\/]style\s*=\s*[-\\])', 4, 'Detects bindings and behavior injections');
INSERT INTO blacklist_filters VALUES (30, '(?:=\s*\w+\s*\+\s*")|(?:\+=\s*\(\s")|(?:!+\s*[\d.,]+\w?\d*\s*\?)|(?:=\s*\[s*\])|(?:"\s*\+\s*")|(?:[^\s]\[\s*\d+\s*\]\s*[;+])|(?:"\s*[&|]+\s*")|(?:\/\s*\?\s*")|(?:\/\s*\)\s*\[)|(?:\d\?.+:\d)|(?:]\s*\[\W*\w)|(?:[^\s]\s*=\s*\/)', 4, 'Detects common XSS concatenation patterns 1/2');
INSERT INTO blacklist_filters VALUES (31, '(?:=\s*\d*\.\d*\?\d*\.\d*)|(?:[|&]{2,}\s*")|(?:!\d+\.\d*\?")|(?:\/:[\w.]+,)|(?:=[\d\W\s]*\[[^]]+\])|(?:\?\w+:\w+)', 4, 'Detects common XSS concatenation patterns 2/2');
INSERT INTO blacklist_filters VALUES (32, '(?:[^\w\s=]on(?!g\&gt;)\w+[^=_+-]*=[^$]+(?:\W|\&gt;)?)', 4, 'Detects possible event handlers');
INSERT INTO blacklist_filters VALUES (33, '(?:\<\w*:?\s(?:[^\>]*)t(?!rong))|(?:\<scri)|(<\w+:\w+)', 4, 'Detects obfuscated script tags and XML wrapped HTML');
INSERT INTO blacklist_filters VALUES (34, '(?:\<\/\w+\s\w+)|(?:@(?:cc_on|set)[\s@,"=])', 4, 'Detects attributes in closing tags and conditional compilation tokens');
INSERT INTO blacklist_filters VALUES (35, '(?:--[^\n]*$)|(?:\<!-|-->)|(?:[^*]\/\*|\*\/[^*])|(?:(?:[\W\d]#|--|{)$)|(?:\/{3,}.*$)|(?:<!\[\W)|(?:\]!>)', 3, 'Detects common comment types');
INSERT INTO blacklist_filters VALUES (37, '(?:\<base\s+)|(?:<!(?:element|entity|\[CDATA))', 5, 'Detects base href injections and XML entity injections');
INSERT INTO blacklist_filters VALUES (38, '(?:\<[\/]?(?:[i]?frame|applet|isindex|marquee|keygen|script|audio|video|input|button|textarea|style|base|body|meta|link|object|embed|param|plaintext|xm\w+|image|im(?:g|port)))', 4, 'Detects possibly malicious html elements including some attributes');
INSERT INTO blacklist_filters VALUES (39, '(?:\\x[01fe][\db-ce-f])|(?:%[01fe][\db-ce-f])|(?:&#[01fe][\db-ce-f])|(?:\\[01fe][\db-ce-f])|(?:&#x[01fe][\db-ce-f])', 5, 'Detects nullbytes and other dangerous characters');
INSERT INTO blacklist_filters VALUES (40, '(?:\)\s*when\s*\d+\s*then)|(?:"\s*(?:#|--|{))|(?:\/\*!\s?\d+)|(?:ch(?:a)?r\s*\(\s*\d)|(?:(?:(n?and|x?or|not)\s+|\|\||\&\&)\s*\w+\()', 6, 'Detects MySQL comments, conditions and ch(a)r injections');
INSERT INTO blacklist_filters VALUES (41, '(?:[\s()]case\s*\()|(?:\)\s*like\s*\()|(?:having\s*[^\s]+\s*[^\w\s])|(?:if\s?\([\d\w]\s*[=<>~])', 6, 'Detects conditional SQL injection attempts');
INSERT INTO blacklist_filters VALUES (42, '(?:"\s*or\s*"?\d)|(?:\\x(?:23|27|3d))|(?:^.?"$)|(?:(?:^["\\]*(?:[\d"]+|[^"]+"))+\s*(?:n?and|x?or|not|\|\||\&\&)\s*[\w"[+&!@(),.-])|(?:[^\w\s]\w+\s*[|-]\s*"\s*\w)|(?:@\w+\s+(and|or)\s*["\d]+)|(?:@[\w-]+\s(and|or)\s*[^\w\s])|(?:[^\w\s:]\s*\d\W+[^\w\s]\s*".)|(?:\Winformation_schema|table_name\W)', 6, 'Detects classic SQL injection probings 1/2');
INSERT INTO blacklist_filters VALUES (43, '(?:"\s*\*.+(?:or|id)\W*"\d)|(?:\^")|(?:^[\w\s"-]+(?<=and\s)(?<=or\s)(?<=xor\s)(?<=nand\s)(?<=not\s)(?<=\|\|)(?<=\&\&)\w+\()|(?:"[\s\d]*[^\w\s]+\W*\d\W*.*["\d])|(?:"\s*[^\w\s?]+\s*[^\w\s]+\s*")|(?:"\s*[^\w\s]+\s*[\W\d].*(?:#|--))|(?:".*\*\s*\d)|(?:"\s*or\s[^\d]+[\w-]+.*\d)|(?:[()*<>%+-][\w-]+[^\w\s]+"[^,])', 6, 'Detects classic SQL injection probings 2/2');
INSERT INTO blacklist_filters VALUES (44, '(?:\d"\s+"\s+\d)|(?:^admin\s*"|(\/\*)+"+\s?(?:--|#|\/\*|{)?)|(?:"\s*or[\w\s-]+\s*[+<>=(),-]\s*[\d"])|(?:"\s*[^\w\s]?=\s*")|(?:"\W*[+=]+\W*")|(?:"\s*[!=|][\d\s!=+-]+.*["(].*$)|(?:"\s*[!=|][\d\s!=]+.*\d+$)|(?:"\s*like\W+[\w"(])|(?:\sis\s*0\W)|(?:where\s[\s\w\.,-]+\s=)|(?:"[<>~]+")', 7, 'Detects basic SQL authentication bypass attempts 1/3');
INSERT INTO blacklist_filters VALUES (45, '(?:union\s*(?:all|distinct|[(!@]*)?\s*[([]*\s*select)|(?:\w+\s+like\s+\")|(?:like\s*"\%)|(?:"\s*like\W*["\d])|(?:"\s*(?:n?and|x?or|not |\|\||\&\&)\s+[\s\w]+=\s*\w+\s*having)|(?:"\s*\*\s*\w+\W+")|(?:"\s*[^?\w\s=.,;)(]+\s*[(@"]*\s*\w+\W+\w)|(?:select\s*[\[\]()\s\w\.,"-]+from)|(?:find_in_set\s*\()', 7, 'Detects basic SQL authentication bypass attempts 2/3');
INSERT INTO blacklist_filters VALUES (46, '(?:in\s*\(+\s*select)|(?:(?:n?and|x?or|not |\|\||\&\&)\s+[\s\w+]+(?:regexp\s*\(|sounds\s+like\s*"|[=\d]+x))|("\s*\d\s*(?:--|#))|(?:"[%&<>^=]+\d\s*(=|or))|(?:"\W+[\w+-]+\s*=\s*\d\W+")|(?:"\s*is\s*\d.+"?\w)|(?:"\|?[\w-]{3,}[^\w\s.,]+")|(?:"\s*is\s*[\d.]+\s*\W.*")', 7, 'Detects basic SQL authentication bypass attempts 3/3');
INSERT INTO blacklist_filters VALUES (47, '(?:[\d\W]\s+as\s*["\w]+\s*from)|(?:^[\W\d]+\s*(?:union|select|create|rename|truncate|load|alter|delete|update|insert|desc))|(?:(?:select|create|rename|truncate|load|alter|delete|update|insert|desc)\s+(?:(?:group_)concat|char|load_file)\s?\(?)|(?:end\s*\);)|("\s+regexp\W)|(?:[\s(]load_file\s*\()', 5, 'Detects concatenated basic SQL injection and SQLLFI attempts');
INSERT INTO blacklist_filters VALUES (48, '(?:@.+=\s*\(\s*select)|(?:\d+\s*or\s*\d+\s*[\-+])|(?:\/\w+;?\s+(?:having|and|or|select)\W)|(?:\d\s+group\s+by.+\()|(?:(?:;|#|--)\s*(?:drop|alter))|(?:(?:;|#|--)\s*(?:update|insert)\s*\w{2,})|(?:[^\w]SET\s*@\w+)|(?:(?:n?and|x?or|not |\|\||\&\&)[\s(]+\w+[\s)]*[!=+]+[\s\d]*["=()])', 6, 'Detects chained SQL injection attempts 1/2');
INSERT INTO blacklist_filters VALUES (49, '(?:"\s+and\s*=\W)|(?:\(\s*select\s*\w+\s*\()|(?:\*\/from)|(?:\+\s*\d+\s*\+\s*@)|(?:\w"\s*(?:[-+=|@]+\s*)+[\d(])|(?:coalesce\s*\(|@@\w+\s*[^\w\s])|(?:\W!+"\w)|(?:";\s*(?:if|while|begin))|(?:"[\s\d]+=\s*\d)|(?:order\s+by\s+if\w*\s*\()|(?:[\s(]+case\d*\W.+[tw]hen[\s(])', 6, 'Detects chained SQL injection attempts 2/2');
INSERT INTO blacklist_filters VALUES (50, '(?:(select|;)\s+(?:benchmark|if|sleep)\s*?\(\s*\(?\s*\w+)', 4, 'Detects SQL benchmark and sleep injection attempts including conditional queries');
INSERT INTO blacklist_filters VALUES (51, '(?:create\s+function\s+\w+\s+returns)|(?:;\s*(?:select|create|rename|truncate|load|alter|delete|update|insert|desc)\s*[\[(]?\w{2,})', 6, 'Detects MySQL UDF injection and other data/structure manipulation attempts');
INSERT INTO blacklist_filters VALUES (52, '(?:alter\s*\w+.*character\s+set\s+\w+)|(";\s*waitfor\s+time\s+")|(?:";.*:\s*goto)', 6, 'Detects MySQL charset switch and MSSQL DoS attempts');
INSERT INTO blacklist_filters VALUES (53, '(?:procedure\s+analyse\s*\()|(?:;\s*(declare|open)\s+[\w-]+)|(?:create\s+(procedure|function)\s*\w+\s*\(\s*\)\s*-)|(?:declare[^\w]+[@#]\s*\w+)|(exec\s*\(\s*@)', 7, 'Detects MySQL and PostgreSQL stored procedure/function injections');
INSERT INTO blacklist_filters VALUES (54, '(?:select\s*pg_sleep)|(?:waitfor\s*delay\s?"+\s?\d)|(?:;\s*shutdown\s*(?:;|--|#|\/\*|{))', 5, 'Detects Postgres pg_sleep injection, waitfor delay attacks and database shutdown attempts');
INSERT INTO blacklist_filters VALUES (55, '(?:\sexec\s+xp_cmdshell)|(?:"\s*!\s*["\w])|(?:from\W+information_schema\W)|(?:(?:(?:current_)?user|database|schema|connection_id)\s*\([^\)]*)|(?:";?\s*(?:select|union|having)\s*[^\s])|(?:\wiif\s*\()|(?:exec\s+master\.)|(?:union select @)|(?:union[\w(\s]*select)|(?:select.*\w?user\()|(?:into[\s+]+(?:dump|out)file\s*")', 5, 'Detects MSSQL code execution and information gathering attempts');
INSERT INTO blacklist_filters VALUES (56, '(?:merge.*using\s*\()|(execute\s*immediate\s*")|(?:\W+\d*\s*having\s*[^\s\-])|(?:match\s*[\w(),+-]+\s*against\s*\()', 5, 'Detects MATCH AGAINST, MERGE, EXECUTE IMMEDIATE and HAVING injections');
INSERT INTO blacklist_filters VALUES (57, '(?:,.*[)\da-f"]"(?:".*"|\Z|[^"]+))|(?:\Wselect.+\W*from)|((?:select|create|rename|truncate|load|alter|delete|update|insert|desc)\s*\(\s*space\s*\()', 5, 'Detects MySQL comment-/space-obfuscated injections and backtick termination');
INSERT INTO blacklist_filters VALUES (58, '(?:@[\w-]+\s*\()|(?:]\s*\(\s*["!]\s*\w)|(?:<[?%](?:php)?.*(?:[?%]>)?)|(?:;[\s\w|]*\$\w+\s*=)|(?:\$\w+\s*=(?:(?:\s*\$?\w+\s*[(;])|\s*".*"))|(?:;\s*\{\W*\w+\s*\()', 7, 'Detects code injection attempts 1/3');
INSERT INTO blacklist_filters VALUES (59, '(?:(?:[;]+|(<[?%](?:php)?)).*(?:define|eval|file_get_contents|include|require|require_once|set|shell_exec|phpinfo|system|passthru|preg_\w+|execute)\s*["(@])', 7, 'Detects code injection attempts 2/3');
INSERT INTO blacklist_filters VALUES (60, '(?:(?:[;]+|(<[?%](?:php)?)).*[^\w](?:echo|print|print_r|var_dump|[fp]open))|(?:;\s*rm\s+-\w+\s+)|(?:;.*{.*\$\w+\s*=)|(?:\$\w+\s*\[\]\s*=\s*)', 7, 'Detects code injection attempts 3/3');
INSERT INTO blacklist_filters VALUES (61, '(?:\w+]?(?<!href)(?<!src)(?<!longdesc)(?<!returnurl)=(?:https?|ftp):)|(?:\{\s*\$\s*\{)', 5, 'Detects url injections and RFE attempts');
INSERT INTO blacklist_filters VALUES (62, '(?:function[^(]*\([^)]*\))|(?:(?:delete|void|throw|instanceof|new|typeof)[^\w.]+\w+\s*[([])|([)\]]\s*\.\s*\w+\s*=)|(?:\(\s*new\s+\w+\s*\)\.)', 5, 'Detects common function declarations and special JS operators');
INSERT INTO blacklist_filters VALUES (63, '(?:[\w.-]+@[\w.-]+%(?:[01][\db-ce-f])+\w+:)', 5, 'Detects common mail header injections');
INSERT INTO blacklist_filters VALUES (64, '(?:\.pl\?\w+=\w?\|\w+;)|(?:\|\(\w+=\*)|(?:\*\s*\)+\s*;)', 5, 'Detects perl echo shellcode injection and LDAP vectors');
INSERT INTO blacklist_filters VALUES (65, '(?:(^|\W)const\s+[\w\-]+\s*=)|(?:(?:do|for|while)\s*\([^;]+;+\))|(?:(?:^|\W)on\w+\s*=[\w\W]*(?:on\w+|alert|eval|print|confirm|prompt))|(?:groups=\d+\(\w+\))|(?:(.)\1{128,})', 5, 'Detects basic XSS DoS attempts');
INSERT INTO blacklist_filters VALUES (67, '(?:\({2,}\+{2,}:{2,})|(?:\({2,}\+{2,}:+)|(?:\({3,}\++:{2,})|(?:\$\[!!!\])', 7, 'Detects unknown attack vectors based on PHPIDS Centrifuge detection');
INSERT INTO blacklist_filters VALUES (68, '(?:[\s\/"]+[-\w\/\\\*]+\s*=.+(?:\/\s*>))', 4, 'Finds attribute breaking injections including obfuscated attributes');
INSERT INTO blacklist_filters VALUES (69, '(?:(?:msgbox|eval)\s*\+|(?:language\s*=\*vbscript))', 4, 'Finds basic VBScript injection attempts');
INSERT INTO blacklist_filters VALUES (70, '(?:\[\$(?:ne|eq|lte?|gte?|n?in|mod|all|size|exists|type|slice|or)\])', 4, 'Finds basic MongoDB SQL injection attempts');
INSERT INTO blacklist_filters VALUES (71, '(?:[\s\d\/"]+(?:on\w+|style|poster|background)=[$"\w])|(?:-type\s*:\s*multipart)', 6, 'Finds malicious attribute injection attempts and MHTML attacks');
INSERT INTO blacklist_filters VALUES (72, '(?:(sleep\((\s*)(\d*)(\s*)\)|benchmark\((.*)\,(.*)\)))', 4, 'Detects blind sqli tests using sleep() or benchmark().');
INSERT INTO blacklist_filters VALUES (73, '(?i:(\%SYSTEMROOT\%))', 4, 'An attacker is trying to locate a file to read or write.');
INSERT INTO blacklist_filters VALUES (74, '(?i:(ping(.*)[\-(.*)\w|\w(.*)\-]))', 5, 'Detects remote code exectuion tests. Will match "ping -n 3 localhost" and "ping localhost -n 3"');
INSERT INTO blacklist_filters VALUES (75, '(?:(((.*)\%[c|d|i|e|f|g|o|s|u|x|p|n]){8}))', 4, 'Looking for a format string attack');
INSERT INTO blacklist_filters VALUES (76, '(?:(union(.*)select(.*)from))', 3, 'Looking for basic sql injection. Common attack string for mysql, oracle and others.');
INSERT INTO blacklist_filters VALUES (77, '(?:^(-0000023456|4294967295|4294967296|2147483648|2147483647|0000012345|-2147483648|-2147483649|0000023456|2.2250738585072007e-308|1e309)$)', 3, 'Looking for intiger overflow attacks, these are taken from skipfish, except 2.2250738585072007e-308 is the "magic number" crash');

INSERT INTO tags VALUES (1, 'xss');
INSERT INTO tags VALUES (2, 'csrf');
INSERT INTO tags VALUES (3, 'dt');
INSERT INTO tags VALUES (4, 'id');
INSERT INTO tags VALUES (5, 'lfi');
INSERT INTO tags VALUES (6, 'rfe');
INSERT INTO tags VALUES (7, 'sqli');
INSERT INTO tags VALUES (8, 'spam');
INSERT INTO tags VALUES (9, 'dos');
INSERT INTO tags VALUES (10, 'files');
INSERT INTO tags VALUES (11, 'exec');
INSERT INTO tags VALUES (12, 'format string');
SELECT pg_catalog.setval('tags_id_seq', 12, true);

INSERT INTO tags_filters VALUES (1, 1);
INSERT INTO tags_filters VALUES (2, 1);
INSERT INTO tags_filters VALUES (1, 2);
INSERT INTO tags_filters VALUES (2, 2);
INSERT INTO tags_filters VALUES (1, 3);
INSERT INTO tags_filters VALUES (2, 3);
INSERT INTO tags_filters VALUES (1, 4);
INSERT INTO tags_filters VALUES (2, 4);
INSERT INTO tags_filters VALUES (1, 5);
INSERT INTO tags_filters VALUES (2, 5);
INSERT INTO tags_filters VALUES (1, 6);
INSERT INTO tags_filters VALUES (2, 6);
INSERT INTO tags_filters VALUES (1, 7);
INSERT INTO tags_filters VALUES (2, 7);
INSERT INTO tags_filters VALUES (1, 8);
INSERT INTO tags_filters VALUES (2, 8);
INSERT INTO tags_filters VALUES (1, 9);
INSERT INTO tags_filters VALUES (2, 9);
INSERT INTO tags_filters VALUES (3, 10);
INSERT INTO tags_filters VALUES (4, 10);
INSERT INTO tags_filters VALUES (5, 10);
INSERT INTO tags_filters VALUES (3, 11);
INSERT INTO tags_filters VALUES (4, 11);
INSERT INTO tags_filters VALUES (5, 11);
INSERT INTO tags_filters VALUES (3, 12);
INSERT INTO tags_filters VALUES (4, 12);
INSERT INTO tags_filters VALUES (5, 12);
INSERT INTO tags_filters VALUES (1, 13);
INSERT INTO tags_filters VALUES (2, 13);
INSERT INTO tags_filters VALUES (1, 14);
INSERT INTO tags_filters VALUES (2, 14);
INSERT INTO tags_filters VALUES (4, 14);
INSERT INTO tags_filters VALUES (6, 14);
INSERT INTO tags_filters VALUES (1, 15);
INSERT INTO tags_filters VALUES (2, 15);
INSERT INTO tags_filters VALUES (4, 15);
INSERT INTO tags_filters VALUES (6, 15);
INSERT INTO tags_filters VALUES (1, 16);
INSERT INTO tags_filters VALUES (2, 16);
INSERT INTO tags_filters VALUES (4, 16);
INSERT INTO tags_filters VALUES (6, 16);
INSERT INTO tags_filters VALUES (1, 17);
INSERT INTO tags_filters VALUES (2, 17);
INSERT INTO tags_filters VALUES (4, 17);
INSERT INTO tags_filters VALUES (6, 17);
INSERT INTO tags_filters VALUES (1, 18);
INSERT INTO tags_filters VALUES (2, 18);
INSERT INTO tags_filters VALUES (4, 18);
INSERT INTO tags_filters VALUES (6, 18);
INSERT INTO tags_filters VALUES (1, 19);
INSERT INTO tags_filters VALUES (2, 19);
INSERT INTO tags_filters VALUES (4, 19);
INSERT INTO tags_filters VALUES (6, 19);
INSERT INTO tags_filters VALUES (1, 20);
INSERT INTO tags_filters VALUES (2, 20);
INSERT INTO tags_filters VALUES (4, 20);
INSERT INTO tags_filters VALUES (6, 20);
INSERT INTO tags_filters VALUES (1, 21);
INSERT INTO tags_filters VALUES (2, 21);
INSERT INTO tags_filters VALUES (4, 21);
INSERT INTO tags_filters VALUES (6, 21);
INSERT INTO tags_filters VALUES (1, 22);
INSERT INTO tags_filters VALUES (2, 22);
INSERT INTO tags_filters VALUES (4, 22);
INSERT INTO tags_filters VALUES (6, 22);
INSERT INTO tags_filters VALUES (1, 23);
INSERT INTO tags_filters VALUES (2, 23);
INSERT INTO tags_filters VALUES (1, 24);
INSERT INTO tags_filters VALUES (2, 24);
INSERT INTO tags_filters VALUES (1, 25);
INSERT INTO tags_filters VALUES (2, 25);
INSERT INTO tags_filters VALUES (1, 26);
INSERT INTO tags_filters VALUES (2, 26);
INSERT INTO tags_filters VALUES (1, 27);
INSERT INTO tags_filters VALUES (6, 27);
INSERT INTO tags_filters VALUES (1, 28);
INSERT INTO tags_filters VALUES (6, 28);
INSERT INTO tags_filters VALUES (5, 28);
INSERT INTO tags_filters VALUES (2, 28);
INSERT INTO tags_filters VALUES (1, 29);
INSERT INTO tags_filters VALUES (2, 29);
INSERT INTO tags_filters VALUES (6, 29);
INSERT INTO tags_filters VALUES (1, 30);
INSERT INTO tags_filters VALUES (2, 30);
INSERT INTO tags_filters VALUES (4, 30);
INSERT INTO tags_filters VALUES (6, 30);
INSERT INTO tags_filters VALUES (1, 31);
INSERT INTO tags_filters VALUES (2, 31);
INSERT INTO tags_filters VALUES (4, 31);
INSERT INTO tags_filters VALUES (6, 31);
INSERT INTO tags_filters VALUES (1, 32);
INSERT INTO tags_filters VALUES (2, 32);
INSERT INTO tags_filters VALUES (1, 33);
INSERT INTO tags_filters VALUES (1, 34);
INSERT INTO tags_filters VALUES (2, 34);
INSERT INTO tags_filters VALUES (1, 35);
INSERT INTO tags_filters VALUES (2, 35);
INSERT INTO tags_filters VALUES (4, 35);
INSERT INTO tags_filters VALUES (1, 37);
INSERT INTO tags_filters VALUES (2, 37);
INSERT INTO tags_filters VALUES (4, 37);
INSERT INTO tags_filters VALUES (1, 38);
INSERT INTO tags_filters VALUES (2, 38);
INSERT INTO tags_filters VALUES (4, 38);
INSERT INTO tags_filters VALUES (6, 38);
INSERT INTO tags_filters VALUES (5, 38);
INSERT INTO tags_filters VALUES (4, 39);
INSERT INTO tags_filters VALUES (6, 39);
INSERT INTO tags_filters VALUES (1, 39);
INSERT INTO tags_filters VALUES (7, 40);
INSERT INTO tags_filters VALUES (4, 40);
INSERT INTO tags_filters VALUES (5, 40);
INSERT INTO tags_filters VALUES (7, 41);
INSERT INTO tags_filters VALUES (4, 41);
INSERT INTO tags_filters VALUES (5, 41);
INSERT INTO tags_filters VALUES (7, 42);
INSERT INTO tags_filters VALUES (4, 42);
INSERT INTO tags_filters VALUES (5, 42);
INSERT INTO tags_filters VALUES (7, 43);
INSERT INTO tags_filters VALUES (4, 43);
INSERT INTO tags_filters VALUES (5, 43);
INSERT INTO tags_filters VALUES (7, 44);
INSERT INTO tags_filters VALUES (4, 44);
INSERT INTO tags_filters VALUES (5, 44);
INSERT INTO tags_filters VALUES (7, 45);
INSERT INTO tags_filters VALUES (4, 45);
INSERT INTO tags_filters VALUES (5, 45);
INSERT INTO tags_filters VALUES (7, 46);
INSERT INTO tags_filters VALUES (4, 46);
INSERT INTO tags_filters VALUES (5, 46);
INSERT INTO tags_filters VALUES (7, 47);
INSERT INTO tags_filters VALUES (4, 47);
INSERT INTO tags_filters VALUES (5, 47);
INSERT INTO tags_filters VALUES (7, 48);
INSERT INTO tags_filters VALUES (4, 48);
INSERT INTO tags_filters VALUES (7, 49);
INSERT INTO tags_filters VALUES (4, 49);
INSERT INTO tags_filters VALUES (7, 50);
INSERT INTO tags_filters VALUES (4, 50);
INSERT INTO tags_filters VALUES (7, 51);
INSERT INTO tags_filters VALUES (4, 51);
INSERT INTO tags_filters VALUES (7, 52);
INSERT INTO tags_filters VALUES (4, 52);
INSERT INTO tags_filters VALUES (7, 53);
INSERT INTO tags_filters VALUES (4, 53);
INSERT INTO tags_filters VALUES (7, 54);
INSERT INTO tags_filters VALUES (4, 54);
INSERT INTO tags_filters VALUES (7, 55);
INSERT INTO tags_filters VALUES (4, 55);
INSERT INTO tags_filters VALUES (7, 56);
INSERT INTO tags_filters VALUES (4, 56);
INSERT INTO tags_filters VALUES (7, 57);
INSERT INTO tags_filters VALUES (4, 57);
INSERT INTO tags_filters VALUES (4, 58);
INSERT INTO tags_filters VALUES (6, 58);
INSERT INTO tags_filters VALUES (5, 58);
INSERT INTO tags_filters VALUES (4, 59);
INSERT INTO tags_filters VALUES (6, 59);
INSERT INTO tags_filters VALUES (5, 59);
INSERT INTO tags_filters VALUES (4, 60);
INSERT INTO tags_filters VALUES (6, 60);
INSERT INTO tags_filters VALUES (5, 60);
INSERT INTO tags_filters VALUES (4, 61);
INSERT INTO tags_filters VALUES (6, 61);
INSERT INTO tags_filters VALUES (5, 61);
INSERT INTO tags_filters VALUES (4, 62);
INSERT INTO tags_filters VALUES (6, 62);
INSERT INTO tags_filters VALUES (5, 62);
INSERT INTO tags_filters VALUES (4, 63);
INSERT INTO tags_filters VALUES (8, 63);
INSERT INTO tags_filters VALUES (5, 64);
INSERT INTO tags_filters VALUES (6, 64);
INSERT INTO tags_filters VALUES (6, 65);
INSERT INTO tags_filters VALUES (9, 65);
INSERT INTO tags_filters VALUES (1, 67);
INSERT INTO tags_filters VALUES (2, 67);
INSERT INTO tags_filters VALUES (4, 67);
INSERT INTO tags_filters VALUES (6, 67);
INSERT INTO tags_filters VALUES (5, 67);
INSERT INTO tags_filters VALUES (1, 68);
INSERT INTO tags_filters VALUES (2, 68);
INSERT INTO tags_filters VALUES (1, 69);
INSERT INTO tags_filters VALUES (2, 69);
INSERT INTO tags_filters VALUES (7, 70);
INSERT INTO tags_filters VALUES (1, 71);
INSERT INTO tags_filters VALUES (2, 71);
INSERT INTO tags_filters VALUES (7, 72);
INSERT INTO tags_filters VALUES (4, 72);
INSERT INTO tags_filters VALUES (10, 73);
INSERT INTO tags_filters VALUES (4, 73);
INSERT INTO tags_filters VALUES (11, 74);
INSERT INTO tags_filters VALUES (4, 74);
INSERT INTO tags_filters VALUES (12, 75);
INSERT INTO tags_filters VALUES (7, 76);
INSERT INTO tags_filters VALUES (4, 76);
INSERT INTO tags_filters VALUES (7, 77);
INSERT INTO tags_filters VALUES (4, 77);

INSERT INTO whitelist_filters VALUES (1, '^[0-9]*$', 1, 'Numeric');
INSERT INTO whitelist_filters VALUES (2, '^-?(?:\d+|\d*(\.|,)\d+)$', 2, 'Numeric (Extended)');
INSERT INTO whitelist_filters VALUES (3, '^[0-9a-f]*$', 5, 'Hexadecimal');
INSERT INTO whitelist_filters VALUES (4, '^[0-9a-z]*$', 6, 'Alphanumeric');
INSERT INTO whitelist_filters VALUES (5, '^[\n0-9a-z+/]+={0,2}$', 10, 'Base64');
INSERT INTO whitelist_filters VALUES (7, '^[\w.:-]*$', 30, 'Word + Special Characters (Simple)');
INSERT INTO whitelist_filters VALUES (6, '^[a-z0-9._%+\-]+@[a-z0-9.-]+\.[a-z]{2,}$', 51, 'E-Mail');
INSERT INTO whitelist_filters VALUES (8, '^((([a-z]{3,9}:(?:\/\/)?)(?:[\-;:&=\+\$,\w]+@)?[a-z0-9\.\-]+|(?:www\.|[\-;:&=\+\$,\w]+@)[a-z0-9\.\-]+)(:\d*)?((?:\/[\+~%\/\.\w\-_]*)?\??(?:[\/\(\)\-\+=&;%@\.\w_]*)#?(?:[\/\-\.\!\/\\\w]*))?)$', 72, 'URL');
INSERT INTO whitelist_filters VALUES (9, '^[\w\s/.,-]*$', 80, 'Word + Whitespace + Special Characters (Simple)');
INSERT INTO whitelist_filters VALUES (10, '^[\w\s/.,=;:+-]*$', 81, 'Word + Whitespace + Special Characters (Medium)');
INSERT INTO whitelist_filters VALUES (11, '^[\w\s/.,=;:()!?*+-]*$', 82, 'Word + Whitespace + Special Characters (Extended)');
INSERT INTO whitelist_filters VALUES (12, '.*', 100, 'Everything');
SELECT pg_catalog.setval('whitelist_filters_id_seq', 12, true);
