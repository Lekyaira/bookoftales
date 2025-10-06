-- Types
CREATE TYPE skill AS ENUM (
	'Acting Disguise', 
	'Appearance', 
	'Bargaining & Evaluation',
	'Beguiling',
	'Courtly Graces',
	'Enduring Hardship',
	'Luck',
	'Magic',
	'Piety',
	'Quick Thinking',
	'Scholarship',
	'Seamanship',
	'Seduction',
	'Stealth & Stealing',
	'Storytelling',
	'Weapon Use',
	'Wilderness Lore',
	'Wisdom'
);

CREATE TYPE attached_skill AS (
	skill skill,
	master boolean
);

CREATE TYPE attached_paragraph AS (
	id int,
	skills skill[]
);

CREATE TYPE attached_rewards AS (
	destiny int,
	story int,
	wealth_id int,
	skills attached_skill[],
	other text[]
);

CREATE TYPE child_paragraph AS (
	body text,
	rewards attached_rewards[]
);

CREATE TYPE paragraph_info AS (
	body text,
	next attached_paragraph,
	prev attached_paragraph,
	sub_paragraphs child_paragraph[],
	skills skill[],
	rewards attached_rewards
);

-- Tables
CREATE TABLE encounter (
	id serial,
	encounter_number int not null,
	roll int not null,
	matrix text not null,
	name text not null,
	PRIMARY KEY(id)
);

CREATE TABLE paragraph (
	id serial,
	body text not null,
	parent_id int default null,
	next_id int default null,
	prev_id int default null,
	PRIMARY KEY(id),
	FOREIGN KEY(parent_id) REFERENCES paragraph(id)
		ON UPDATE CASCADE
		ON DELETE SET NULL,
	FOREIGN KEY(next_id) REFERENCES paragraph(id)
		ON UPDATE CASCADE
		ON DELETE SET NULL,
	FOREIGN KEY(prev_id) REFERENCES paragraph(id)
		ON UPDATE CASCADE
		ON DELETE SET NULL
);

CREATE TABLE matrix_action (
	encounter_id int not null,
	action text not null,
	paragraph_id int not null,
	PRIMARY KEY(encounter_id, action),
	FOREIGN KEY(encounter_id) REFERENCES encounter(id)
		ON UPDATE CASCADE
		ON DELETE CASCADE,
	FOREIGN KEY(paragraph_id) REFERENCES paragraph(id)
		ON UPDATE CASCADE
);

CREATE TABLE mastery_skill (
	id serial,
	paragraph_id int not null,
	skill skill not null,
	PRIMARY KEY(id),
	FOREIGN KEY(paragraph_id) REFERENCES paragraph(id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

CREATE TABLE wealth (
	id serial,
	title text not null,
	movement_land int not null,
	movement_sea int not null,
	next int,
	prev int,
	PRIMARY KEY(id),
	FOREIGN KEY(next) REFERENCES wealth(id)
		ON DELETE SET NULL,
	FOREIGN KEY(prev) REFERENCES wealth(id)
		ON DELETE SET NULL
);

CREATE TABLE reward (
	id serial,
	paragraph_id int not null,
	PRIMARY KEY(id),
	FOREIGN KEY(paragraph_id) REFERENCES paragraph(id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

CREATE TABLE reward_destiny (
	reward_id int not null,
	amount int not null,
	PRIMARY KEY(reward_id, amount),
	FOREIGN KEY(reward_id) REFERENCES reward(id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

CREATE TABLE reward_story (
	reward_id int not null,
	amount int not null,
	PRIMARY KEY(reward_id, amount),
	FOREIGN KEY(reward_id) REFERENCES reward(id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

CREATE TABLE reward_wealth (
	reward_id int not null,
	amount int not null,
	PRIMARY KEY(reward_id, amount),
	FOREIGN KEY(reward_id) REFERENCES reward(id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

CREATE TABLE reward_skill (
	reward_id int not null,
	skill skill not null,
	master boolean not null default false,
	PRIMARY KEY(reward_id, skill),
	FOREIGN KEY(reward_id) REFERENCES reward(id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

CREATE TABLE reward_text (
	reward_id int not null,
	reward text not null,
	PRIMARY KEY(reward_id, reward),
	FOREIGN KEY(reward_id) REFERENCES reward(id)
		ON UPDATE CASCADE
		ON DELETE CASCADE
);

-- Functions
CREATE FUNCTION lookup_encounter (encounter_number int, roll int)
RETURNS TABLE(action text, paragraph_id int)
AS $$
BEGIN
	RETURN QUERY
	SELECT m.action, m.paragraph_id FROM matrix_action m 
	LEFT JOIN encounter e
	ON m.encounter_id = e.id
	WHERE e.encounter_number = encounter_number
	AND e.roll = roll;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION get_mastery_skills (paragraph_id int)
RETURNS TABLE(skills skill[])
AS $$
BEGIN
	RETURN QUERY
	SELECT ARRAY(SELECT skill FROM mastery_skill s 
		JOIN paragraph p 
		ON s.paragraph_id = p.id);
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION get_rewards (paragraph_id int)
RETURNS TABLE(rewards attached_rewards)
AS $$
BEGIN
	RETURN QUERY
	SELECT d.amount, 
	s.amount, 
	w.id, 
	ARRAY(SELECT rs.skill, rs.master 
		FROM reward_skill rs
		WHERE rs.reward_id = r.id) AS attached_skill,
	ARRAY(SELECT rt.reward
		FROM reward_text rt
		WHERE rt.reward_id = r.id) AS text
	FROM reward r
	JOIN reward_destiny d ON d.reward_id = r.id
	JOIN reward_story s ON s.reward_id = r.id
	JOIN reward_wealth w ON w.reward_id = r.id
	WHERE r.parapraph_id = parapraph_id;
END
$$ LANGUAGE plpgsql;

CREATE FUNCTION get_paragraph (paragraph_id int)
RETURNS SETOF paragraph_info
AS $$
BEGIN
	RETURN QUERY
	SELECT p.body, 
	(p.next_id, get_mastery_skills(p.next_id)) AS attached_paragraph,
	(p.prev_id, get_mastery_skills(p.prev_id)) AS attached_paragraph,
	ARRAY(SELECT c.body, get_rewards(c.id) FROM paragraph c
		WHERE c.parent_id = p.id) AS child_paragraph,
	get_mastery_skills(p.id),
	get_rewards(p.id)
	FROM paragraph p
	WHERE p.id = paragraph_id;
END
$$ LANGUAGE plpgsql;
