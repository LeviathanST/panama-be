CREATE TYPE cate AS ENUM('PANAMA_VISUAL', '3D_MAPPING', 'INTERACT_DANCE', 'HOLOGRAM');
CREATE TABLE IF NOT EXISTS "user"(
    id                       SERIAL PRIMARY KEY,
    username                 VARCHAR(25) UNIQUE NOT NULL,
    password                 VARCHAR(255) NOT NULL
);
CREATE TABLE IF NOT EXISTS project(
    id                      SERIAL PRIMARY KEY,
    title                   VARCHAR(255) NOT NULL,
    thumbnail               VARCHAR(255) NOT NULL,
    description             VARCHAR(255) NOT NULL,
    category                cate NOT NULL,
    time                    VARCHAR(60)
);
CREATE TABLE IF NOT EXISTS image(
    id                  SERIAL PRIMARY KEY,
    url                 VARCHAR(255) UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS video(
    id                  SERIAL PRIMARY KEY,
    url                 VARCHAR(255) UNIQUE NOT NULL
);
CREATE TABLE IF NOT EXISTS image_project(
    project_id          SERIAL,
    image_id            SERIAL UNIQUE,

    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE,
    FOREIGN KEY (image_id) REFERENCES image(id) ON DELETE CASCADE,

    PRIMARY KEY (project_id, image_id)
);
CREATE TABLE IF NOT EXISTS video_project(
    project_id          SERIAL UNIQUE,
    video_id            SERIAL UNIQUE,

    FOREIGN KEY (project_id) REFERENCES project(id) ON DELETE CASCADE,
    FOREIGN KEY (video_id) REFERENCES video(id) ON DELETE CASCADE,

    PRIMARY KEY (project_id, video_id)
);
