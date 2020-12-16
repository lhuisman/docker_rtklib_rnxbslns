-- Table: public.xyzrtklib

-- DROP TABLE public.xyzrtklib;

CREATE TABLE public.xyzrtklib
(
    gid integer NOT NULL DEFAULT nextval('xyzrtklib_gid_seq'::regclass),
    datetime timestamp without time zone,
    base character varying(25) COLLATE pg_catalog."default",
    rover character varying(25) COLLATE pg_catalog."default",
    epochs numeric(5,0),
    fixedepochs numeric(5,0),
    x_median numeric(14,4),
    y_median numeric(14,4),
    z_median numeric(14,4),
    x_mean numeric(14,4),
    y_mean numeric(14,4),
    z_mean numeric(14,4),
    x_std numeric(12,5),
    y_std numeric(12,5),
    z_std numeric(12,5),
    n_std numeric(12,5),
    e_std numeric(12,5),
    u_std numeric(12,5),
    CONSTRAINT xyzrtklib_pkey PRIMARY KEY (gid)
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE public.xyzrtklib
    OWNER to postgres;