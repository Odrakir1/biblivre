--
-- PostgreSQL database dump
--

-- Dumped from database version 11.16 (Debian 11.16-1.pgdg90+1)
-- Dumped by pg_dump version 11.18 (Ubuntu 11.18-1.pgdg22.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: global; Type: SCHEMA; Schema: -; Owner: biblivre
--

CREATE SCHEMA global;


ALTER SCHEMA global OWNER TO biblivre;

--
-- Name: update_translation(character varying, character varying, character varying, integer); Type: FUNCTION; Schema: global; Owner: biblivre
--

CREATE FUNCTION global.update_translation(character varying, character varying, character varying, integer) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
 DECLARE
	p_language ALIAS FOR $1;
	p_key ALIAS FOR $2;
	p_text ALIAS FOR $3;
	p_user ALIAS FOR $4;

	v_schema character varying;
	v_current_value TEXT;
	v_global_value TEXT;
	v_user_created BOOLEAN;
	v_query_string character varying;
 BEGIN
	v_schema = current_schema();
	
	IF v_schema <> 'global' THEN
		-- Get the global value for this key
		SELECT INTO v_global_value text FROM global.translations
		WHERE language = p_language AND key = p_key;

		-- If the new text is the same as the global one,
		-- delete it from the current schema
		IF v_global_value = p_text THEN
			-- Fix for unqualified schema in functions
			EXECUTE 'DELETE FROM ' || pg_catalog.quote_ident(v_schema) || '.translations WHERE language = ' || pg_catalog.quote_literal(p_language) || ' AND key = ' || pg_catalog.quote_literal(p_key);
			-- The code below will only work with multiple schemas after Postgresql 9.3
			-- DELETE FROM translations WHERE language = p_language AND key = p_key;
			RETURN 1;
		END IF;
	END IF;

	-- Get the current value for this key
	
	-- Fix for unqualified schema in functions
	EXECUTE 'SELECT text FROM ' || pg_catalog.quote_ident(v_schema) || '.translations WHERE language = ' || pg_catalog.quote_literal(p_language) || ' AND key = ' || pg_catalog.quote_literal(p_key) INTO v_current_value;
	-- The code below will only work with multiple schemas after Postgresql 9.3
	-- SELECT INTO v_current_value text FROM translations WHERE language = p_language AND key = p_key;
	
	-- If the new text is the same as the current one,
	-- return
	IF v_current_value = p_text THEN
		RETURN 2;
	END IF;

	-- If the new key isn't available in the global schema,
	-- then this is a user_created key
	v_user_created = v_schema <> 'global' AND v_global_value IS NULL;

	-- If the current value is null then there is no
	-- current translation for this key, then we should
	-- insert it
	IF v_current_value IS NULL THEN
		EXECUTE 'INSERT INTO ' || pg_catalog.quote_ident(v_schema) || '.translations (language, key, text, created_by, modified_by, user_created) VALUES (' || pg_catalog.quote_literal(p_language) || ', ' || pg_catalog.quote_literal(p_key) || ', ' || pg_catalog.quote_literal(p_text) || ', ' || pg_catalog.quote_literal(p_user) || ', ' || pg_catalog.quote_literal(p_user) || ', ' || pg_catalog.quote_literal(v_user_created) || ');';

		-- The code below will only work with multiple schemas after Postgresql 9.3
		--INSERT INTO translations
		--(language, key, text, created_by, modified_by, user_created)
		--VALUES
		--(p_language, p_key, p_text, p_user, p_user, v_user_created);
		
		RETURN 3;
	ELSE
		EXECUTE 'UPDATE ' || pg_catalog.quote_ident(v_schema) || '.translations SET text = ' || pg_catalog.quote_literal(p_text) || ', modified = now(), modified_by = ' || pg_catalog.quote_literal(p_user) || ' WHERE language = ' || pg_catalog.quote_literal(p_language) || ' AND key = ' || pg_catalog.quote_literal(p_key);

		-- The code below will only work with multiple schemas after Postgresql 9.3
		--UPDATE translations
		--SET text = p_text,
		--modified = now(),
		--modified_by = p_user
		--WHERE language = p_language AND key = p_key;
		
		RETURN 4;
	END IF;
 END;
 $_$;


ALTER FUNCTION global.update_translation(character varying, character varying, character varying, integer) OWNER TO biblivre;

--
-- Name: update_user_value(integer, character varying, character varying, character varying); Type: FUNCTION; Schema: global; Owner: biblivre
--

CREATE FUNCTION global.update_user_value(integer, character varying, character varying, character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
 DECLARE
	p_id ALIAS FOR $1;
	p_key ALIAS FOR $2;
	p_value ALIAS FOR $3;
	p_ascii ALIAS FOR $4;

	v_schema character varying;
	v_current_value TEXT;
 BEGIN
	v_schema = current_schema();

	IF v_schema = 'global' THEN
		-- Can't save user fields in global schema
		RETURN 1;
	END IF;

	-- Get the current value for this key
	EXECUTE 'SELECT value FROM ' || pg_catalog.quote_ident(v_schema) || '.users_values WHERE user_id = ' || pg_catalog.quote_literal(p_id) || ' AND key = ' || pg_catalog.quote_literal(p_key) INTO v_current_value;
	-- SELECT INTO v_current_value value FROM users_values WHERE user_id = p_id AND key = p_key;

	-- If the new value is the same as the current one,
	-- return
	IF v_current_value = p_value THEN
		RETURN 2;
	END IF;

	-- If the current value is null then there is no
	-- current value for this key, then we should
	-- insert it
	IF v_current_value IS NULL THEN
		-- RAISE LOG 'inserting into schema %', v_schema;
		EXECUTE 'INSERT INTO ' || pg_catalog.quote_ident(v_schema) || '.users_values (user_id, key, value, ascii) VALUES (' || pg_catalog.quote_literal(p_id) || ', ' || pg_catalog.quote_literal(p_key) || ', ' || pg_catalog.quote_literal(p_value) || ', ' || pg_catalog.quote_literal(p_ascii) || ');';
		--INSERT INTO users_values (user_id, key, value, ascii) VALUES (p_id, p_key, p_value, p_ascii);
		
		RETURN 3;
	ELSE
		EXECUTE 'UPDATE ' || pg_catalog.quote_ident(v_schema) || '.users_values SET value = ' || pg_catalog.quote_literal(p_value) || ', ascii = ' || pg_catalog.quote_literal(p_ascii) || ' WHERE user_id = ' || pg_catalog.quote_literal(p_id) || ' AND key = ' || pg_catalog.quote_literal(p_key);
		-- UPDATE users_values SET value = p_value, ascii = p_ascii WHERE user_id = p_id AND key = p_key;

		RETURN 4;
	END IF;
 END;
$_$;


ALTER FUNCTION global.update_user_value(integer, character varying, character varying, character varying) OWNER TO biblivre;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: backups; Type: TABLE; Schema: global; Owner: biblivre
--

CREATE TABLE global.backups (
    id integer NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    path character varying,
    schemas character varying NOT NULL,
    type character varying NOT NULL,
    scope character varying NOT NULL,
    downloaded boolean DEFAULT false NOT NULL,
    steps integer,
    current_step integer
);


ALTER TABLE global.backups OWNER TO biblivre;

--
-- Name: backups_id_seq; Type: SEQUENCE; Schema: global; Owner: biblivre
--

CREATE SEQUENCE global.backups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE global.backups_id_seq OWNER TO biblivre;

--
-- Name: backups_id_seq; Type: SEQUENCE OWNED BY; Schema: global; Owner: biblivre
--

ALTER SEQUENCE global.backups_id_seq OWNED BY global.backups.id;


--
-- Name: configurations; Type: TABLE; Schema: global; Owner: biblivre
--

CREATE TABLE global.configurations (
    key character varying NOT NULL,
    value character varying NOT NULL,
    type character varying DEFAULT 'string'::character varying NOT NULL,
    required boolean DEFAULT false NOT NULL,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    modified_by integer
);


ALTER TABLE global.configurations OWNER TO biblivre;

--
-- Name: logins; Type: TABLE; Schema: global; Owner: biblivre
--

CREATE TABLE global.logins (
    id integer NOT NULL,
    login character varying NOT NULL,
    employee boolean DEFAULT false NOT NULL,
    password text NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    created_by integer,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    modified_by integer
);


ALTER TABLE global.logins OWNER TO biblivre;

--
-- Name: logins_id_seq; Type: SEQUENCE; Schema: global; Owner: biblivre
--

CREATE SEQUENCE global.logins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE global.logins_id_seq OWNER TO biblivre;

--
-- Name: logins_id_seq; Type: SEQUENCE OWNED BY; Schema: global; Owner: biblivre
--

ALTER SEQUENCE global.logins_id_seq OWNED BY global.logins.id;


--
-- Name: schemas; Type: TABLE; Schema: global; Owner: biblivre
--

CREATE TABLE global.schemas (
    schema character varying NOT NULL,
    name character varying,
    disabled boolean DEFAULT false NOT NULL
);


ALTER TABLE global.schemas OWNER TO biblivre;

--
-- Name: translations; Type: TABLE; Schema: global; Owner: biblivre
--

CREATE TABLE global.translations (
    language character varying NOT NULL,
    key character varying NOT NULL,
    text text NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL,
    created_by integer,
    modified timestamp without time zone DEFAULT now() NOT NULL,
    modified_by integer,
    user_created boolean DEFAULT false NOT NULL
);


ALTER TABLE global.translations OWNER TO biblivre;

--
-- Name: versions; Type: TABLE; Schema: global; Owner: biblivre
--

CREATE TABLE global.versions (
    installed_versions character varying NOT NULL
);


ALTER TABLE global.versions OWNER TO biblivre;

--
-- Name: backups id; Type: DEFAULT; Schema: global; Owner: biblivre
--

ALTER TABLE ONLY global.backups ALTER COLUMN id SET DEFAULT nextval('global.backups_id_seq'::regclass);


--
-- Name: logins id; Type: DEFAULT; Schema: global; Owner: biblivre
--

ALTER TABLE ONLY global.logins ALTER COLUMN id SET DEFAULT nextval('global.logins_id_seq'::regclass);


--
-- Data for Name: backups; Type: TABLE DATA; Schema: global; Owner: biblivre
--

COPY global.backups (id, created, path, schemas, type, scope, downloaded, steps, current_step) FROM stdin;
\.


--
-- Data for Name: configurations; Type: TABLE DATA; Schema: global; Owner: biblivre
--

COPY global.configurations (key, value, type, required, modified, modified_by) FROM stdin;
holding.label_print_paragraph_alignment	ALIGN_CENTER	string	t	2014-06-21 11:42:07.150326	1
general.default_language	pt-BR	string	t	2013-04-13 13:37:22.871407	\N
search.results_per_page	25	integer	t	2013-04-13 13:37:22.871407	\N
search.result_limit	6000	integer	t	2013-04-13 13:37:22.871407	\N
general.currency	R$	string	t	2014-02-22 15:20:28.594713	\N
cataloging.accession_number_prefix	Bib	string	t	2014-02-22 15:20:56.235706	\N
search.distributed_search_limit	100	integer	t	2014-02-22 15:21:15.676016	\N
general.business_days	2,3,4,5,6	string	t	2014-02-22 15:22:11.189584	\N
general.uid		string	f	2014-05-21 21:46:46.702	0
general.multi_schema	false	boolean	t	2014-06-14 18:32:29.586269	1
general.psql_path		string	f	2014-06-21 11:40:03.8973	1
general.pg_dump_path		string	f	2014-06-21 11:40:03.8973	1
general.backup_path		string	f	2014-06-21 11:40:03.8973	1
general.subtitle	Versão 5.0 Beta	string	f	2022-12-04 11:05:55.5474	1
general.title	Biblivre V	string	t	2022-12-04 11:05:55.5474	1
\.


--
-- Data for Name: logins; Type: TABLE DATA; Schema: global; Owner: biblivre
--

COPY global.logins (id, login, employee, password, created, created_by, modified, modified_by) FROM stdin;
1	admin	t	C4wx3TpMHnSwdk1bUQ/V6qwAQmw=	2013-04-13 13:38:46.652058	\N	2014-06-21 11:40:36.422497	1
\.


--
-- Data for Name: schemas; Type: TABLE DATA; Schema: global; Owner: biblivre
--

COPY global.schemas (schema, name, disabled) FROM stdin;
single	Biblivre IV	f
\.


--
-- Data for Name: translations; Type: TABLE DATA; Schema: global; Owner: biblivre
--

COPY global.translations (language, key, text, created, created_by, modified, modified_by, user_created) FROM stdin;
pt-BR	administration.configuration.title.holding.label_print_paragraph_alignment	Alinhamento de parágrafo	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
es	administration.configuration.title.holding.label_print_paragraph_alignment	Alineación de párrafo	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
en-US	administration.configuration.title.holding.label_print_paragraph_alignment	Paragraph alignment	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
pt-BR	administration.configuration.description.holding.label_print_paragraph_alignment	Alinhamento de parágrafo que será utilizado em cada etiqueta impressa	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
es	administration.configuration.description.holding.label_print_paragraph_alignment	Alineación de párrafo que va a ser usado en cada etiqueta impresa	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
en-US	administration.configuration.description.holding.label_print_paragraph_alignment	Paragraph alignment which will be used in each printed label	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
pt-BR	administration.configuration.label_print.ALIGN_CENTER	Centralizado	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
es	administration.configuration.label_print.ALIGN_CENTER	Centrado	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
en-US	administration.configuration.label_print.ALIGN_CENTER	Center	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
pt-BR	administration.configuration.label_print.ALIGN_JUSTIFIED_ALL	Justificado (tudo)	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
es	administration.configuration.label_print.ALIGN_JUSTIFIED_ALL	Justificado (todo)	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
en-US	administration.configuration.label_print.ALIGN_JUSTIFIED_ALL	Justified (all)	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
pt-BR	administration.configuration.label_print.ALIGN_JUSTIFIED	Justificado	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
es	administration.configuration.label_print.ALIGN_JUSTIFIED	Justificado	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
en-US	administration.configuration.label_print.ALIGN_JUSTIFIED	Justified	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
pt-BR	administration.configuration.label_print.ALIGN_LEFT	À esquerda	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
es	administration.configuration.label_print.ALIGN_LEFT	A la izquierda	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
en-US	administration.configuration.label_print.ALIGN_LEFT	Left	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
pt-BR	administration.configuration.label_print.ALIGN_RIGHT	À direita	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
es	administration.configuration.label_print.ALIGN_RIGHT	A la derecha	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
en-US	administration.configuration.label_print.ALIGN_RIGHT	Right	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
pt-BR	multi_schema.configuration.title.general.title	Nome deste Grupo de Bibliotecas	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
pt-BR	multi_schema.configurations.page_help	A rotina de Configurações de Multi-bibliotecas permite alterar configurações globais do grupo de bibliotecas e configurações padrão que serão usadas pelas bibliotecas cadastradas. Todas as configurações marcadas com um asterisco (*) serão usadas por padrão em novas bibliotecas cadastradas neste grupo, mas podem ser alteradas internamente pelos administradores, através da opção <em>"Administração"</em>, <em>"Configurações"</em>, no menu superior.	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
pt-BR	menu.multi_schema_translations	Traduções	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
pt-BR	multi_schema.configuration.title.general.subtitle	Subtítulo deste Grupo de Bibliotecas	2014-06-21 11:54:49.572182	1	2014-06-21 11:54:49.572182	1	f
pt-BR	menu.administration_access_cards	Cartões de Acesso	2014-06-21 12:23:05.099501	1	2014-06-21 12:23:05.099501	1	f
pt-BR	multi_schema.manage.disable	Desabilitar biblioteca	2014-06-21 17:04:41.838396	1	2014-06-21 17:35:14.546952	1	f
pt-BR	multi_schema.manage.enable	Habilitar biblioteca	2014-06-21 17:04:41.838396	1	2014-06-21 17:35:14.546952	1	f
pt-BR	circulation.user_reservation.page_help	<p>Para realizar uma reserva, você deverá selecionar o registro que será reservado. Para encontrar o registro, realize uma pesquisa similar à pesquisa bibliográfica.</p>	2014-07-05 11:47:02.155561	1	2014-07-05 11:47:02.155561	1	f
pt-BR	warning.download_site	Ir para o site de downloads	2014-07-05 11:47:02.155561	1	2014-07-05 11:47:02.155561	1	f
pt-BR	administration.configurations.error.invalid	O valor especificado para uma das configurações não é valido, verifique os erros abaixo	2014-06-14 19:34:08.805257	1	2014-07-05 11:47:02.155561	1	f
pt-BR	menu.circulation_user_reservation	Reservas do Leitor	2014-07-05 11:47:02.155561	1	2014-07-05 11:47:02.155561	1	f
pt-BR	administration.permissions.items.circulation_user_reservation	Efetuar Reserva para si mesmo	2014-07-05 11:47:02.155561	1	2014-07-05 11:47:02.155561	1	f
pt-BR	administration.configuration.title.logged_in_text	Texto inicial para usuários logados	2014-07-12 11:21:42.419959	1	2014-07-12 11:21:42.419959	1	f
pt-BR	administration.configuration.title.logged_out_text	Texto inicial para usuários não logados	2014-07-12 11:21:42.419959	1	2014-07-12 11:21:42.419959	1	f
pt-BR	multi_schema.manage.new_schema.field.subtitle	Subtítulo da biblioteca	2014-06-14 19:50:04.110972	1	2014-06-14 19:50:04.110972	1	f
es	marc.bibliographic.datafield.700.subfield.b	Numeración que sigue al nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.error.save	Falla al guardar la cotización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.700.subfield.e	Relación con el documento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.confirm_delete_record.trash	Será movido para la base de datos "papelera de reciclaje"	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.automatic_holding.holding_acquisition_type	Tipo de Adquisición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_field.type	Tipo de usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.title.title	Título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.indicator.1.1	Genera entrada para el título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.indicator.1.0	No genera entrada para el título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.680.subfield.a	Nota de alcance	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.indicator.1	Número de caracteres a ser despreciados en la alfabetización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field_count.description	<p>Luego de seleccionar el campo Marc y la Ordenación, realice la búsqueda bibliográfica que servirá de base para el Informe, o haga click en <strong>Emitir Informe</strong> para utilizar toda la base bibliográfica.</p>\n<p><strong>Atención:</strong> Este Informe puede llevar algunos minutos para ser generado, dependiendo del tamaño de la base bibliográfica.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.end_number	Número final	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.modified_between	Alterado entre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.form.hidden_subfields_singular	Exhibir subcampo oculto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
pt-BR	acquisition.request.field.author_numeration	Numeração que segue o prenome	2014-06-21 14:25:12.053902	1	2014-06-21 14:25:12.053902	1	f
pt-BR	administration.setup.cancel	Cancelar	2014-06-21 14:25:12.053902	1	2014-06-21 14:25:12.053902	1	f
pt-BR	administration.maintenance.reinstall.title	Restauração e Reconfiguração	2014-06-21 14:25:12.053902	1	2014-06-21 14:25:12.053902	1	f
pt-BR	administration.maintenance.reinstall.button	Ir para a tela de restauração e reconfiguração	2014-06-21 14:25:12.053902	1	2014-06-21 14:25:12.053902	1	f
pt-BR	acquisition.request.field.author_title	Título e outras palavras associadas ao nome	2014-06-21 14:25:12.053902	1	2014-06-21 14:25:12.053902	1	f
pt-BR	search.bibliographic.select_item_button	Selecionar registro	2014-06-21 14:25:12.053902	1	2014-06-21 14:25:12.053902	1	f
pt-BR	administration.maintenance.reinstall.confirm.title	Ir para a tela de restauração e reconfiguração	2014-06-21 14:25:12.053902	1	2014-06-21 14:25:12.053902	1	f
pt-BR	acquisition.request.field.author_type	Tipo de Autor	2014-06-21 14:25:12.053902	1	2014-06-21 14:25:12.053902	1	f
pt-BR	administration.maintenance.reinstall.confirm.question	Atenção: Todas as opções farão com que os dados de sua biblioteca sejam apagados em favor dos dados recuperados. Recomenda-se fazer um backup antes de iniciar esta ação. Deseja continuar?	2014-06-21 14:25:12.053902	1	2014-06-21 17:04:41.838396	1	f
pt-BR	multi_schema.manage.error.cant_disable_last_library	Não é possível desabilitar todas as bibliotecas deste grupo. Ao menos uma deve ficar habilitada.	2014-06-21 17:35:14.546952	1	2014-06-21 17:35:14.546952	1	f
pt-BR	multi_schema.manage.error.toggle	Erro ao trocar estado da biblioteca.	2014-06-21 17:35:14.546952	1	2014-06-21 17:35:14.546952	1	f
pt-BR	multi_schema.configurations.error.disable_multi_schema_schema_count	Não é possível desabilitar o sistema de multi-bibliotecas enquanto houver mais de uma biblioteca habilitada.	2014-06-21 17:35:14.546952	1	2014-06-21 17:35:14.546952	1	f
pt-BR	multi_schema.configurations.error.disable_multi_schema_outside_global	Não é possível desabilitar o sistema de multi-bibliotecas de dentro de uma biblioteca.	2014-06-21 17:35:14.546952	1	2014-06-21 17:35:14.546952	1	f
pt-BR	cataloging.bibliographic.automatic_holding_help	<p>Utilize os campos abaixo para acelerar o processo de catalogação de exemplares. O preenchimento é opcional e nenhum exemplar será criado caso nenhum campo seja preenchido. Neste caso, você poderá criar exemplares manualmente, com o formulário completo, pela aba <em>Exemplares</em>.</p><p>Caso seja do seu interesse cadastrar exemplares agora, o único campo que precisa sempre ser preenchido é o Número de Exemplares. Para cada volume da obra serão criados esta quantidade selecionada de exemplares, portanto, se o registro bibliográfico possuir 3 volumes e você preencher o Número de Exemplares com o número 2 e o Número de Volumes da Obra com o número 3, serão criados 6 exemplares, 2 para o Volume 1, 2 para o Volume 2 e 2 para o Volume 3. Caso os exemplares sejam de apenas um volume, preencha o campo Número do Volume, e, caso a obra não tenha volumes, deixe ambos os campo em branco.</p>	2014-07-05 17:20:32.670746	1	2014-07-05 17:20:32.670746	1	f
pt-BR	cataloging.bibliographic.automatic_holding.holding_count	Número de Exemplares	2014-07-05 17:20:32.670746	1	2014-07-05 17:20:32.670746	1	f
pt-BR	cataloging.bibliographic.automatic_holding_title	Exemplares Automáticos	2014-07-05 17:20:32.670746	1	2014-07-05 17:20:32.670746	1	f
pt-BR	cataloging.bibliographic.automatic_holding.holding_acquisition_date	Data de aquisição	2014-07-05 17:20:32.670746	1	2014-07-05 17:20:32.670746	1	f
pt-BR	cataloging.bibliographic.automatic_holding.holding_library	Biblioteca Depositária	2014-07-05 17:20:32.670746	1	2014-07-05 17:20:32.670746	1	f
pt-BR	menu.self_circulation	Reservas	2014-07-05 17:20:32.670746	1	2014-07-05 17:20:32.670746	1	f
pt-BR	cataloging.bibliographic.automatic_holding.holding_acquisition_type	Tipo de Aquisição	2014-07-05 17:20:32.670746	1	2014-07-05 17:20:32.670746	1	f
pt-BR	cataloging.bibliographic.automatic_holding.holding_volume_number	Número do Volume	2014-07-05 17:20:32.670746	1	2014-07-05 17:20:32.670746	1	f
pt-BR	cataloging.bibliographic.automatic_holding.holding_volume_count	Quantidade de volumes da Obra	2014-07-05 17:20:32.670746	1	2014-07-05 17:20:32.670746	1	f
es	administration.z3950.error.save	Falla al guardar el servidor z39.50	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.confirm_delete_record.trash	Será movido para la base de datos "papelera de reciclaje"	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.administration_access_cards	Tarjetas de Acceso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.field.quantity	Cantidad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.acquisition_order_save	Guardar registro de pedido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.administration_restore	Recuperar copia de seguridad de la base de datos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.id_rg	Identidad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.translations.download.button	Descargar el idioma	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.circulation_user_reservation	Efectuar Reserva para sí mismo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
pt-BR	multi_schema.manage.error	Erro	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	multi_schema.manage.new_schema.title	Criação de Nova Biblioteca	2014-06-14 19:50:04.110972	1	2014-06-14 19:50:04.110972	1	f
pt-BR	multi_schema.manage.new_schema.field.schema	Atalho da Biblioteca	2014-06-14 19:50:04.110972	1	2014-06-14 19:50:04.110972	1	f
pt-BR	menu.multi_schema_configurations	Configurações	2014-06-14 19:50:04.110972	1	2014-06-14 19:50:04.110972	1	f
pt-BR	menu.multi_schema_manage	Gerência de Bibliotecas	2014-06-14 19:50:04.110972	1	2014-06-14 19:50:04.110972	1	f
pt-BR	multi_schema.manage.new_schema.field.title	Nome da biblioteca	2014-06-14 19:50:04.110972	1	2014-06-14 19:50:04.110972	1	f
pt-BR	multi_schema.manage.new_schema.button.create	Criar Biblioteca	2014-06-14 19:50:04.110972	1	2014-06-14 19:50:04.110972	1	f
pt-BR	text.multi_schema.select_library	Lista de Bibliotecas	2014-06-14 19:50:04.110972	1	2014-06-14 19:50:04.110972	1	f
pt-BR	menu.multi_schema	Multi-bibliotecas	2014-06-14 19:50:04.110972	1	2014-06-14 19:50:04.110972	1	f
pt-BR	multi_schema.manage.schemas.title	Lista de Bibliotecas deste Servidor	2014-06-14 19:50:04.110972	1	2014-06-14 19:50:04.110972	1	f
es	cataloging.bibliographic.button.edit	Editar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.label_digital_media_only	Backup de archivos digitales	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.user_type.field.reservation_time_limit	Plazo de reserva	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.600.subfield.k	Subencabezamientos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	format.datetime_user_friendly	DD/MM/AAAA hh:mm	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.acquisition_supplier_save	Guardar registro de proveedor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.confirm_delete_record_title.inactive	Marcar usuario como "inactivo"	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.operator	Operador	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.600.subfield.t	Título de la obra junto a la entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.600.subfield.q	Forma completa del nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.confirm_delete_record_question.forever	¿Usted realmente desea excluir este registro de solicitud?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_710	Autor secundario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.record_will_be_ignored	Este registro no será importado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_711	Autor secundario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.600.subfield.d	Fechas asociadas al nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configurations.error.value_must_be_numeric	El valor de este campo debe ser un número	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.title.summary	Informe de Sumario del Catálogo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.550	TG (Término genérico)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.600.subfield.a	Apellido y/o nombre del autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.field.status	Situación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_field.id	Matrícula	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.600.subfield.b	Numeración que sigue al nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.issn	ISSN	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.600.subfield.c	Título y otras palabras asociadas al nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.confirm_remove_attachment_description	¿Usted desea excluir este archivo digital?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.user_type.simple_term_title	Rellene el Tipo de Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	warning.reindex_database	Usted precisa reindizar las bases de datos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.groups.cataloging	Catalogación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.user.select_item_button	Seleccionar registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.advanced_search	Búsqueda Bibliográfica Avanzada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.600.subfield.z	Subdivisión geográfica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.amount	Cantidad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.600.subfield.x	Subdivisión general	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.600.subfield.y	Subdivisión cronológica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.users_without_user_card	Listar solamente Usuarios que nunca tuvieron tarjeta impresa	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.confirm_remove_attachment	Excluir archivo digital	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.confirm_delete_record_question	¿Usted realmente desea excluir este registro de solicitud?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.holding.error.accession_number_unavailable	Este sello patrimonial ya está en uso por otro ejemplar. Por favor, rellene otro valor o deje en blanco para que el sistema calcule uno automáticamente.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.confirm_delete_record_title.forever	Excluir registro de solicitud	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.author_type.100	Persona	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.button.add	Agregar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.change_status.title.uncancel	Recuperar Tarjeta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
pt-BR	menu.multi_schema_backup	Backup e Restauração	2014-07-19 11:28:35.848301	1	2014-07-19 11:28:35.848301	1	f
es	cataloging.bibliographic.button.export_records	Exportar registros	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.confirm_delete_record_title.forever	Excluir registro de proveedor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.circulation_user	Registro de Usuarios	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	text.main.noscript		2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.title.dewey	Informe de Clasificación Dewey	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.administration_reports	Informes	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.digits	Dígitos significativos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.material_type.object_3d	Objeto 3D	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.button.cancel	Cancelar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.field.supplier	Proveedor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.022.subfield.a	Número de ISSN	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.title.general.title	Nombre de la biblioteca	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.013.subfield.e	Estado de la patente	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.error.record_not_found	Registro no encontrado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.013.subfield.d	Fecha	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.013.subfield.f	Parte de un documento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.confirm_cancel_editing.2	Todas las alteraciones serán perdidas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.confirm_cancel_editing.1	¿Usted desea cancelar la edición de este registro de Pedido?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.256.subfield.a	Características del archivo de computadora	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.date_from	De	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.date	Fecha	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.button_exclude_digital_media	Crear backup sin archivos digitales	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.title.general.psql_path	Camino para el programa psql	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.cataloging	Catalogación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.vocabulary_913	Código Regional	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.013.subfield.a	Número	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.013.subfield.b	País	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.013.subfield.c	Tipo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.indicator.1.0	Ningún carácter a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.indicator.1.1	1 carácter a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.indicator.1.2	2 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.upload_button	Enviar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.indicator.1.7	7 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.title.search.distributed_search_limit	Límite de resultados para búsquedas distribuidas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.indicator.1.8	8 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.default	Seleccione...	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.indicator.1.9	9 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.490.indicator.1	Política de desdoblamiento de serie	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.title.unit_value	Valor Unitario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.users_who_have_login_access	Listar solo Usuarios que poseen login de acceso al Biblivre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.indicator.1.3	3 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.indicator.1.4	4 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.indicator.1.5	5 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.field.email	Email	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.circulation_user_cards	Impresión de Carnets	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.indicator.1.6	6 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.attachment.alias	Digite un nombre para este archivo digital	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.fieldset.title_info	Datos de la Obra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.611.indicator.1.2	apellido compuesto (obsoleto)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.611.indicator.1.3	nombre de familia	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.field.created	Fecha del Pedido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_730	Título uniforme	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.records_found_plural	{0} registros encontrados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.100.indicator.1	Forma de entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
pt-BR	circulation.lending.receipt.lendings	Empréstimos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
es	cataloging.holding.error.shouldnt_delete_because_holding_is_or_was_lent	Este ejemplar está o ya fue prestado y no debe ser excluido. En caso que no este más disponible, el procedimiento correcto es cambiar su disponibilidad para No disponible. Si desea igualmente excluir este ejemplar, presione el botón <b>"Forzar Exclusión"</b>.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.automatic_holding_help	<p>Utilice los campos abajo para acelerar el proceso de catalogación de ejemplares. El rellenado es opcional y no se creará ningún ejemplar en caso de no se rellene ningún campo. En este caso, usted podrá crear ejemplares manualmente, con el formulario completo, por la pestaña <em>Exemplares</em>.</p><p>En caso de ser de su interés registrar ejemplares ahora, el único campo que precisa ser rellenado siempre es el Número de Ejemplares. Para cada volumen de la obra se creará esta cantidad seleccionada de ejemplares, por lo tanto si el registro bibliográfico posee 3 volúmenes y usted rellena el Número de Ejemplares con el número 2 y el Número de Volúmenes de la Obra con el número 3, se crearán 6 ejemplares, 2 para el Volumen 1, 2 para el Volumen 2 y 2 para el Volumen 3. En caso de que los ejemplares sean de solamente un volumen, rellene el campo Número del Volumen, y, en caso de que la obra no tenga volúmenes, deje ambos campos en blanco.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.611.indicator.1.0	nombre simple o compuesto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.611.indicator.1.1	apellido simple o compuesto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.082	Clasificación Decimal Dewey	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.080	Clasificación Decimal Universal	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.title_last_backups	Últimos Backups	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.receipt.lendings	Préstamos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.555.indicator.1.8	No generar constante en la exhibición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.marc_popup.title	Editar Registro MARC	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.access_control.arrival_time	Fecha de entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.record.success.update	Registro alterado con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.fieldset.dewey	Clasificación Dewey	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.title.requisition	Solicitud	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.555.indicator.1.0	Índice remisivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.button.save	Guardar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.indicator.1.0	No genera entrada para el título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.indicator.1.1	Genera entrada para el título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.button.save	Guardar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.administration_z3950_delete	Excluir registro de servidor z3950	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.fine_value	Valor de la multa	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.095	Área de conocimiento de CNPq	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.error.no_users_found	Ningún usuario encontrado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.090	Número de llamada - Localización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.confirm_delete_record_title	Excluir registro de cotización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.access_control.card_unavailable	Tarjeta no disponible	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.simple_term_title	Rellena el Código de la Tarjeta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.error.invalid_restore_path	El directorio configurado para la restauración de los archivos de backup no es válido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.title.general.pg_dump_path	Camino para el programa pg_dump	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.add_one_card	Registrar Nueva Tarjeta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.administration_z3950_save	Guardar registro de servidor z3950	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.fine_popup.title	Devolución atrasada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.confirm_move_record_description_plural	¿Usted realmente desea mover estos {0} registros?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.labels.button.select_item	Seleccionar ejemplar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.isbn	ISBN	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.title.general.backup_path	Camino de destino de las copias de seguridad (Backups)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_300	Descripción física	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.confirm_cancel_editing.2	Todas las alteraciones se perderán	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.translations.upload.button	Enviar el idioma	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.340.subfield.e	Soporte	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.confirm_cancel_editing.1	¿Usted desea cancelar la edición de este usuario?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.340.subfield.c	Materiales aplicados a la superficie	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.340.subfield.d	Técnica en que se registra la información	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_306	Tiempo de duración	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.340.subfield.a	Base y configuración del material	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.340.subfield.b	Dimensiones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	error.invalid_method_call	Llamada con método inválido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.indicator.2._	ninguna información suministrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.authorities_411	Otra forma de nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.authorities_410	Otra forma de nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.migration.groups.cataloging_bibliographic	Catálogo Bibliográfico y de Ejemplares	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.distributed.issn	ISSN (incluyendo guiones)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	error.no_permission	Usted no tiene permiso para ejecutar esta acción	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.button.new	Nuevo usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.confirm_delete_record.forever	Será excluido permanentemente del sistema y no podrá ser recuperado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.750.indicator.2	Tesauro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.750.indicator.1	Nivel del Asunto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.help_manual	Manual	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.field.id	N&ordm; del registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.all_users	Informe de Todos los Usuarios	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.field.invoice_number	N&ordm; de la Factura	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.vocabulary.indexing_groups.te_term	Término Específico (TE)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.610.subfield.x	Subdivisión general	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.610.subfield.y	Subdivisión cronológica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.610.subfield.z	Subdivisión geográfica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.450.subfield.a	Término tópico no usado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.description_last_backups_1	Abajo están los enlaces para download de los últimos backups realizados. Es importante guardarlos en un lugar seguro, pues esta es la única forma de recuperar sus datos, en caso de que sea necesario.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.description_last_backups_2	Estos archivos están guardados en el directorio especificado en la configuración del Biblivre (<em>"Administración"</em>, <em>"Configuraciones"</em>, en el menú superior). En caso que este directorio no esté disponible para la escritura en el momento del backup, un directorio temporal será usado en su lugar. Por este motivo, algunos de los backups pueden no estar disponibles luego de cierto tiempo. <span class="attention">Recomendamos siempre hacer un download del backup y guardarlo en un lugar seguro.</span>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.users.title	Buscar Lector	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.040.subfield.e	Fuentes convencionales de descripciones de datos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.title.logged_in_text	Texto inicial para usuarios logueados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.040.subfield.d	Agencia que alteró el registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.700.indicator.1.3	nombre de familia	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.040.subfield.c	Agencia que transcribió el registro en formato legible por máquina	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.040.subfield.b	Idioma de la catalogación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.040.subfield.a	Código de la Agencia Catalogadora	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.700.indicator.1.0	nombre simple o compuesto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.700.indicator.1.1	apellido simple o compuesto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	error.invalid_json	El Biblivre no fue capaz de entender los datos recibidos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.700.indicator.1.2	apellido compuesto (obsoleto)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	aquisition.request.error.request_not_found	No fue posible encontrar la requerimiento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.database	Base	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.description.4	El Backup solamente de archivos digitales es una copia de todos los archivos de medio digital que fueron grabados en el Biblivre, sin ningún otro dato o información, como usuarios, base catalográfica, etc.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.id_cpf	CPF	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.success.block	Tarjeta bloqueada con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.z3950.error.delete	Falla al excluir el servidor z39.50	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.upload_popup.processing	Procesando...	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.610.subfield.c	Lugar de realización del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.description.search.results_per_page	Esta configuración representa la cantidad máxima de resultados que serán exhibidos en una única página en las búsquedas del sistema. Un número muy grande podrá dejar el sistema más lento.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.610.subfield.d	Fecha de realización del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.610.subfield.a	Nombre de la entidad o del lugar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.610.subfield.b	Unidades subordinadas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.password	Contraseña	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.user_name	Nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.button_digital_media_only	Crear backup de archivos digitales	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.610.subfield.n	Número de la parte - sección de la obra - orden del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.user_status.active	Activo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.610.subfield.l	Idioma del texto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.translations.error.save	No fue posible guardar las traducciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.610.subfield.k	Subencabezamiento. (enmiendas, protocolos, selección, etc)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.610.subfield.g	Información adicional	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.authorities_400	Otra forma de nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.610.subfield.t	Título de la obra junto a la entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.biblivre4restore.confirm_description	¿Usted realmente desea restaurar este Backup?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.710.indicator.2	Tipo de entrada secundaria	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.confirm_move_record_title	Mover registros	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.710.indicator.1	Forma de entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.custom_count	Informe de recuento del campo Marc	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.user_signup	Fecha de Matrícula	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.550.subfield.z	Subdivisión geográfica adoptada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.550.subfield.x	Subdivisión general adoptada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.550.subfield.y	Subdivisión cronológica adoptada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.progress_popup.processing	El Biblivre de esta biblioteca está en manutención. Aguarde hasta que la misma sea concluida.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.fieldset.dates	Período	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.362.subfield.z	Fuente de información	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.error.user_not_found	Usuario no encontrado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.migration.groups.users	Usuarios, Logins de acceso y Tipos de Usuarios	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.step_1_description	En este paso, usted puede importar un archivo conteniendo registros en los formatos MARC, XML y ISO2709 o realizar una búsqueda en otras bibliotecas. Seleccione abajo el modo de importación deseado, seleccionando el archivo o rellenando los términos de la búsqueda. En el paso siguiente, usted podrá seleccionar cuales registros deberán ser importados.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.vocabulary.confirm_delete_record_question	¿Usted realmente desea excluir este registro de vocabulario?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	header.law	Ley de Incentivo a la Cultura	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.printer_type.printer_24_columns	Impresora 24 columnas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.material_type.book	Libro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.database_count	Total de Registros en las Bases en el Período	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.913.subfield.a	Código Lugar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.acquisition	Fecha de adquisición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.source_file_subtitle	Seleccione un archivo conteniendo los registros a ser importados. El formato de este archivo puede ser <strong>texto</strong>, <strong>XML</strong> o <strong>ISO2709</strong>, desde que la catalogación original sea compatible con MARC.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.confirm_delete_record_question.forever	¿Usted realmente desea excluir este usuario?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.670	Origen de las informaciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.title.general.default_language	Idioma estándar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.description.general.default_language	Esta configuración representa el idioma padrón para la exhibición del Biblivre.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.indicator.2	Número de caracteres a ser despreciados en la alfabetización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.indicator.1	Genera entrada secundaria en la ficha	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.translations.error.java_locale_not_available	No existe un identificador de idioma java para el archivo de traducciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.description.circulation.lending_receipt.printer.type	Esta configuración representa el tipo de impresora que será utilizada para la impresión de recibos de préstamos.  Los valores posibles son: impresora de 40 columnas, de 80 columnas, o impresora común (chorro de tinta).	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.685	Nota de historial o glosario (GLOSS)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.indicator.2.0	Parte del título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.z3950.field.port	Puerta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.translations.upload.field.upload_file	Archivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.680	Nota de alcance (NE)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	multi_schema.manage.new_schema.field.subtitle	Subtítulo de la biblioteca	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.label.author_count	Cantidad de registros	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.indicator.2.5	Título adicional en carátula secundaria	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.indicator.2.6	Título de partida	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.indicator.2.7	Título corriente	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.indicator.2.8	Título del lomo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.indicator.2.1	Título paralelo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.loading	Cargando	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.indicator.2.2	Título específico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.indicator.2.3	Otro título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.indicator.2.4	Título de la tapa	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.step_2_description	En este paso, verifique los registros que serán importados e impórtelos individualmente o en conjunto, a través de los botones disponibles al final de la página. El Biblivre detecta automáticamente si el registro es bibliográfico, autoridades o vocabulario, sin embargo permite que el usuario corrija antes de la importación. <strong>Importante:</strong> Los registros importados serán agregados a la Base de Trabajo y deberán ser corregidos y ajustados antes de ser movidos para la Base Principal. Eso evita que registros incorrectos sean agregados directamente a la base de datos final.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.field.terms_of_payment	Forma de pago	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_310	Peridiocidad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.450	UP (remisiva para TE no usado)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.reservation.reserve_failure	Falla al reservar la obra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.550.subfield.a	Término tópico adoptado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.summary	Sumario del Catálogo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.option.dewey	Clasificación Decimal Dewey	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_reservation.page_help	<p>Para realizar una reserva, usted deberá selecionar el registro a ser reservado. Para encontrar el registro, realice una búsqueda similar a la búsqueda bibliográfica.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.040	Fuente de la Catalogación (NR)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.362.subfield.a	Información de Fechas de Publicación y/o Volumen	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.success.update	Proveedor guardado con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	multi_schema.manage.button.show_log	Exhibir log	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.change_password.current_password	Contraseña actual	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.830.subfield.v	Número del volumen o designación secuencial de la serie	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.indicator.1.0	Clasificación de la LC	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.reservation.error.select_reader_first	Para reservar un registro usted precisa, primeramente, seleccionar un lector	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.670.subfield.a	Nombre retirado de	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.indicator.1.2	National Library of Medicine Classification	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.indicator.1.1	CDD	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.indicator.1.4	Localización fija	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.indicator.1.3	Superintendent of Documents classification	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.indicator.1.6	En parte separado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.operator.and_not	y no	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.indicator.1.5	Título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.indicator.1.7	Clasificación específica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.indicator.1.8	Otro esquema	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.material_type.periodic	Periódico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.830.subfield.a	Título Uniforme	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.edition	Edición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_field.name	Nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.title.all_users	Informe General de Usuarios	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.949.subfield.a	Sello Patrimonial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.dewey	CDD	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.field.author_numeration	Numeración que sigue el prenombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.labels.popup.title	Formato de las etiquetas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.isbn_already_in_database	Ya existe un registro con este ISBN en la base de datos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.090.subfield.a	Clasificación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.record.success.delete	Registro excluido con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.090.subfield.b	Código del autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.090.subfield.c	Edición - volumen	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.vocabulary_040	Fuente de catalogación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.090.subfield.d	Número del Ejemplar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.holdings_lent	Prestados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.description.search.result_limit	Esta configuración representa la cantidad máxima de resultados que serán encontrados en una búsqueda catalográfica. Este límite es importante para evitar lentitudes en el Biblivre en bibliotecas que posean una gran cantidad de registros. En caso de que la cantidad de resultados de la búsqueda del usuario exceda este límite, será recomendado que se mejoren los filtros de búsqueda.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.555.indicator.1._	Índice	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.record_imported_successfully	Registro importado con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.buttons.dismiss_fine	Abonar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.returned_lendings	Préstamos devueltos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.257.subfield.a	País de la entidad productora	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.back_to_search	Regresar a la búsqueda	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.vocabulary_450	Término Use Para	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	error.invalid_database		2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.button.edit_marc	Editar MARC	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.z3950.success.save	Servidor z39.50 guardado con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.wait	Aguarde	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.611.subfield.y	Subdivisión cronológica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.611.subfield.x	Subdivisión general	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.indicator.1._	Ninguna información suministrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.611.subfield.z	Subdivisión geográfica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.material_type.music	Música	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630	Asunto - Título uniforme	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.z3950.success.delete	Servidor z39.50 excluido con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.611.subfield.t	Título de la obra junto a la entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.611.subfield.n	Número de orden del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.field.status	Situación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_362	Fecha de la primera publicación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	language_code	es	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.611.subfield.e	Nombre de las subunidades del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.611.subfield.d	Fecha de realización del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.611.subfield.c	Lugar de realización del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.670.subfield.b	Información encontrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.611.subfield.a	Nombre del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.receipt.lending_date	Fecha de Préstamo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.buttons.pay_fine	Pagar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.410.subfield.a	Nombre de la entidad o del lugar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.migration.groups.cataloging_vocabulary	Catálogo de Vocabulario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.page_help	<p>La rutina de Permisos permite la creación de Login y Contraseña para un usuario, así como la definición de sus permisos de acceso o utilización de las diversas rutinas del Biblivre.</p>\n<p>La búsqueda tratará de encontrar los Usuarios ya registrados en el Biblivre, y funciona de la misma manera que la búsqueda simplificada de la rutina de Registro de Usuarios.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.confirm_delete_record.trash	Será movido para la base de datos "papelera de reciclaje"	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.indexing_groups.all	Cualquier campo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.651	Asunto - Nombre geográfico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.650	Asunto - Tópico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.confirm_delete_record.forever	La Tarjeta será excluida permanentemente del sistema y no podrá ser recuperada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.help_faq	Preguntas Frecuentes	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.distributed.subject	Asunto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.success.save	Tarjeta incluida con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	warning.download_site	Ir para el sitio de descargas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.acquisition_order	Pedidos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_852	Notas públicas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.translations.error.load	No fue posible leer el archivo de traducciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.translations.upload_popup.title	Enviando Archivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.id	Nro. Registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.error.no_request_found	No fue posible encontrar ninguna Solicitud	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.confirm_delete_record.forever	Será excluido permanentemente del sistema y no podrá ser recuperado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.cataloging_bibliographic_save	Guardar registro bibliográfico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.original_value	Valor original	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.material_type.photo	Foto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.acquisition_supplier_delete	Excluir registro de proveedor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.z3950.confirm_delete_record_question.forever	¿Usted realmente desea excluir este Servidor Z39.50?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.confirm_delete_record.trash	Será movido para la base de datos "papelera de reciclaje"	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.z	Nota estándar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.q	Descripción del índice en multimedio	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.p	Descripción de la colección en multimedio	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.o	Descripción del índice en microfilm	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_830	Título uniforme	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.n	Descripción de la colección en microfilm	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.u	Descripción del índice en otros soportes	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.material_type.pamphlet	Panfleto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.t	Descripción de la colección en otros soportes	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.s	Descripción del índice en braile	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.r	Descripción de la colección en braile	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.i	Descripción del índice con acceso on-line	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.f	Código de la biblioteca en el CCN	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.g	Descripción del índice de colección impresa	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.l	Descripción de la colección en microficha	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.m	Descripción del índice en microficha	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.j	Descripción de la colección en CD-ROM	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.750.indicator.2	Tesauro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.k	Descripción del índice en CD-ROM	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.750.indicator.1	Nivel del Asunto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.search_authorities	Autoridades	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.610	Asunto - Entidad Colectiva	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.a	Sigla de la biblioteca	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.description.general.psql_path	Atención: Esta es una configuración avanzada, pero importante. El Biblivre intentará encontrar automáticamente el camino para el programa <strong>psql</strong> y, excepto en casos donde sea exhibido un error abajo, usted no precisará alterar esta configuración. Esta configuración representa el camino, en el servidor donde el Biblivre está instalado, para lo ejecutable <strong>psql</strong> que es distribuído junto al PostgreSQL. En caso que esta configuración estuviera inválida, el Biblivre no será capaz de generar y restaurar copias de seguridad.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.611	Asunto - Evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.d	Año de la última adquisición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.e	Localización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.b	Descripción de la colección impresa	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947.subfield.c	Tipo de adquisición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.automatic_holding.holding_volume_number	Número del Volumen	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
pt-BR	common.open	Abrir	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
es	administration.maintenance.backup.error.no_schema_selected	Ninguna biblioteca seleccionada.	2014-07-19 11:28:46.69376	1	2014-07-26 10:56:23.669888	1	f
es	circulation.access_control.card_in_use	Tarjeta en uso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.fieldset.field_count	Recuento por campo Marc	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.041.subfield.b	Código de idioma del sumario o resumen	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.041.subfield.a	Código del idioma de texto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.holding.confirm_delete_record_question	¿Usted realmente desea excluir este registro de ejemplar?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.reindex.button_bibliographic	Reindizar base bibliográfica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.option.database.main	Principal	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.600	Asunto - Nombre personal	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.field.status	Situación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.041.subfield.h	Código de idioma del documento original	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.045.indicator.1.0	Fecha - período únicos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.045.indicator.1.2	Extensión de fechas - períodos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.045.indicator.1.1	Fecha - período múltiples	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.indexing_groups.subject	Asunto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.confirm_delete_record.inactive	Saldrá de la lista de búsquedas y solo podrá ser encontrado a través de la "búsqueda avanzada", de donde podrá ser excluido permanentemente o recuperado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.address_complement	Complemento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.cataloging_bibliographic_private_database_access	Acceso a la Base Privada.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.150.subfield.z	Subdivisión geográfica adoptada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.150.subfield.y	Subdivisión cronológica adoptada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.place	Lugar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.150.subfield.x	Subdivisión general adoptada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.isrc	ISRC	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.migration.groups.lendings	Préstamos activos, historia de préstamos y multas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.150.subfield.a	Término tópico adoptado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.342.subfield.d	Escala de Longitud	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.342.subfield.c	Escala de Latitud	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.user_type.error.save	Falla al guardar el Tipo de Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.migration.groups.acquisition	Adquisiciones (Proveedor, Requerimiento, Cotización y Pedido)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.database.trash_full	Papelera de Reciclaje	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.status.any	Cualquier	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.reservation.users.title	Buscar Lector	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.confirm_delete_record_question.forever	¿Usted realmente desea excluir esta Tarjeta?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	field.error.invalid	Este valor no es válido para este campo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.150.subfield.i	Calificador	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.342.subfield.a	Nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.342.subfield.b	Unidad de las Coordenadas o Unidad de la Distancia	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.administration_usertype_save	Guardar registro de tipo de usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.access.user.search	Usuarios	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.vocabulary.indexing_groups.all	Cualquier campo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_876	Nota de acceso restricto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.change_status.question.unblock	¿Desea realmente desbloquear esta Tarjeta?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.100.indicator.1.3	nombre de familia	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.material_type.movie	Película	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.100.indicator.1.1	apellido simple o compuesto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.migration.groups.cataloging_authorities	Catálogo de Autoridades	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.100.indicator.1.2	nombre compuesto (obsoleto)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.100.indicator.1.0	nombre simple o compuesto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.holdings	Informe de Registro de Ejemplares	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.automatic_holding.holding_count	Número de Ejemplares	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.indicator.2.3	3 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
pt-BR	common.save	Salvar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
es	acquisition.quotation.field.unit_value	Valor Unitario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.110.indicator.1	Forma de entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.indicator.2.2	2 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.711.indicator.1	Forma de entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.indicator.2.1	1 carácter a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.indicator.2.0	Ningún carácter a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.indicator.2.7	7 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.indicator.2.6	6 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.cancel	Cancelar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.indicator.2.5	5 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.indicator.2.4	4 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.administration_usertype_delete	Excluir registro de tipo de usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.indicator.2.9	9 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.indicator.2.8	8 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.open	Abrir	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.status.in_use	En uso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.save_as_new	Guardar como Nuevo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	error.void		2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.author	Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.670	Orígen de las informaciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.field.info	Observaciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.author	Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.status.cancelled	Cancelado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.error.invalid_backup_type	El modo de backup seleccionado no existe	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.operator.or	o	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.110	Autor - Entidad colectiva	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.111	Autor - Evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.fieldset.author	Búsqueda por Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.subfield.b	Complemento del título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.user_type.field.lending_limit	Límite de préstamos simultáneos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	label.username	Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.error.delete.user_has_lendings	Este usuario posee préstamos activos.  Realice la devolución antes de excluir este usuario.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.subfield.a	Título/título abreviado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.access_control.user_has_card	Usuario ya posee tarjeta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.accesscards.select_card	Seleccionar Tarjeta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.subfield.g	Miscelánea	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.subfield.f	Información de volumen/número de fascículo y/o fecha de la obra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.no_backups_found	Ningún backup encontrado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.warning	Este proceso puede demorar algunos minutos, dependiendo de la configuración de hardware de su servidor.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.subfield.i	Exhibir texto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.subfield.h	Medio físico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.504.subfield.a	Notas de bibliografía	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.receipt.expected_return_date	Fecha para devolución	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.z3950.field.name	Nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.invalid_backup_path	Camino inválido. Este directorio no existe o el Biblivre no posee permiso de escritura.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.vocabulary.confirm_delete_record.trash	Será movido para la base de datos "papelera de reciclaje"	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.subfield.n	Número de la parte/sección de la obra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.subfield.p	Nombre de la parte/sección de la obra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.100	Autor - Nombre personal	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.title.logged_out_text	Texto inicial para usuarios no logueados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.new_value	Nuevo valor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.access_control.page_help	<p>O <strong>"Control de Acceso"</strong> permite administrar la entrada y permanencia de los lectores en las instalaciones de la biblioteca. Seleccione el lector a través de una búsqueda por nombre o matrícula y digite el número de una tarjeta de acceso disponible para vincular aquella tarjeta al lector.</p>\n<p>En el momento de la salida del lector, usted podrá desvincular la tarjeta procurando por el código del mismo</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.700.indicator.2.2	entrada analítica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.field.title	Título Principal	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.distributed.author	Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.indexing_groups.total	Total	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.marc_field	Valor del campo Marc	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.indicator.2	Número de caracteres a ser despreciados en la alfabetización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.material_type.computer_legible	Archivo de Computadora	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.indicator.1	Genera entrada secundaria en la ficha	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.usertype.confirm_delete_record.forever	El Tipo de Usuario será excluido permanentemente del sistema y no podrá ser recuperado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.translations.upload.title	Enviar archivo de idioma	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.administration_datamigration	Importar datos del Biblivre 3	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130	Obra anónima	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.error.save	Falla al guardar la Tarjeta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.address	Dirección	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.distributed.page_help	<p>La búsqueda distribuida permite recuperar informaciones sobre registros en acervos de otras bibliotecas, que colocan a disposición sus registros para la búsqueda y catalogación colaborativa.</p>\n<p>Para realizar una búsqueda, rellene los términos de la búsqueda, seleccionando el campo de interés. En seguida, seleccione una o más bibliotecas donde se deberán localizar los registros. <span class="warn">Atención: seleccione pocas bibliotecas para evitar que la búsqueda distribuida sea muy lenta, entendiendo que ella depende de la comunicación entre las bibliotecas y el tamaño de cada acervo.</span></p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.save	Guardar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.printer_type.printer_common	Impresora común	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.number_of_titles	Número de Títulos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.button.continue_to_biblivre	Ir para el Biblivre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.user_count_by_type	Totales por Tipos de Usuarios	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.step_2_title	Seleccionar registros para importación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.employee	Empleado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.current_value	Valor actual	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.uncancel	Recuperar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.biblivre4restore.title_found_backups	Backups Encontrados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.record.error.delete	Falla al excluir el Registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.confirm_cancel_editing_title	Cancelar edición de registro de Pedido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permission.error.delete	Falla al excluir el login	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.user_status.blocked	Bloqueado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.biblivre4restore.success.description	Backup restaurado con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.start_date	Fecha Inicial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.680.subfield.a	Nota de alcance	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.button.return	Devolver	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.confirm_cancel_editing_title	Cancelar edición de usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.095.subfield.a	Área de conocimiento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.vocabulary.confirm_cancel_editing.2	Se perderán todas las alteraciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.vocabulary.confirm_cancel_editing.1	¿Usted desea cancelar la edición de este registro de vocabulario?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.import_as	Importar como:	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.cataloging_authorities_save	Guardar registro de autoridad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.confirm_delete_record.forever	Será excluido permanentemente del sistema y no podrá ser recuperado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.material_type.thesis	Tesis	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.import_popup.importing	Importando registros, por favor, aguarde	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.fieldset.title.values	Valores	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.150	TE	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.acquisition_request	Requerimientos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.750.indicator.1.0	Ningún nivel especificado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.750.indicator.1.1	Asunto primario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.750.indicator.1.2	Asunto secundario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.translations.download.description	Seleccione abajo el idioma que desea descargar.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.field.zip_code	Código Postal	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.button.delete	Excluir	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.migration.groups.z3950_servers	Servidores Z39.50	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.lending_date	Fecha del préstamo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.field.info	Observaciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.field.trademark	Nombre de Fantasía	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.remove_item_button	Excluir	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	multi_schema.manage.new_schema.title	Creación de Nueva Biblioteca	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.045.indicator.1._	Subcampos |b o |c no están presentes	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.other_name	Otra Forma de nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	aquisition.supplier.error.supplier_not_found	No fue posible encontrar el proveedor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_cards.button.print_user_cards	Imprimir carnets	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.vocabulary.indexing_groups.tg_term	Término General (TG)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.change_password.description.6	En caso que el usuario pierda su contraseña, deberá igualmente entrar en contacto con el Administrador o Bibliotecario responsable por el Biblivre, que podrá proveer una nueva contraseña.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.issn_already_in_database	Ya existe un registro con este ISSN en la base de datos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.subfield.a	Título uniforme atribuido al documento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.z3950.field.url	URL	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.550.subfield.y	Subdivisión cronológica adoptada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.error.delete	Falla al excluir la Tarjeta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.550.subfield.z	Subdivisión geográfica adoptada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.subfield.d	Fecha que aparece junto al título uniforme en la entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.address_zip	CEP	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.subfield.l	Idioma del texto. Idioma del texto por extenso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.subfield.k	Subencabezamientos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.subfield.f	Fecha de edición del ítem que está siendo procesado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.button.show_log	Exhibir log	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.subfield.g	Información adicional	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.913.subfield.a	Código Lugar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.receipt.return_date	Fecha de devolución	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.change_password.description.1	El cambio de contraseña es el proceso por el cual un usuario puede alterar su contraseña actual por una nueva. Por cuestiones de seguridad, sugerimos que el usuario realice este procedimiento periódicamente.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.record.error.move	Falla al mover los Registros	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.administration_datamigration	Migración de Datos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.change_password.description.3	Mezcle letras, símbolos especiales y números en su contraseña	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.change_password.description.2	La única regla para creación de contraseñas en el Biblivre es la cantidad mínima de 3 caracteres. Sin embargo, sugerimos seguir las siguientes directivas:	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.subfield.p	Nombre de la parte - sección de la obra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.page_help	<p>La importación de registros permite expandir su base de datos sin que haya necesidad de catalogación manual. Nuevos registros pueden ser importados a través de búsquedas Z39.50 o a partir de archivos exportados por otros sistemas de biblioteconomía.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.change_password.description.5	Use una cantidad de caracteres superior al recomendado.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.change_password.description.4	Use letras mayúsculas y minúsculas; y	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.550.subfield.a	Término tópico adoptado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.subfield.y	Subdivisión cronológica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.subfield.z	Subdivisión geográfica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.subfield.x	Subdivisión general	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.750.subfield.z	Subdivisión geográfica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.750.subfield.y	Subdivisión cronológica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.750.subfield.x	Subdivisión general	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.block	Bloquear	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.949.subfield.a	Sello patrimonial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.750.subfield.a	Término tópico adoptado en el tesauro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.410.subfield.a	Nombre de la entidad o del lugar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.550.subfield.x	Subdivisión general adoptada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.renew_success	Préstamo renovado con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.cataloging_vocabulary	Vocabulario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.labels.never_printed	Listar solamente ejemplares que nunca tuvieron etiquetas impresas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.user_total_lending_list	Historial de préstamos a este lector	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.material_type.manuscript	Manuscrito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.operator.and	y	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.step	Paso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.cataloging_authorities_delete	Excluir registro de autoridad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.change_status.question.cancel	¿Desea realmente cancelar esta Tarjeta?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.reinstall.title	Restauración y Reconfiguración	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.button.cancel	Cancelar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.success.generate	Informe generado con éxito. El mismo será abierto en otra página.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.labels.selected_records_singular	{0} ejemplar seleccionado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.502.subfield.a	Notas de disertación o tesis	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.auto_download	Backup realizado, descargando automáticamente en algunos segundos...	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.groups.acquisition	Adquisición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.database.record_deleted	Registro excluido definitivamente	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.040.subfield.c	Agencia que transcribió el registro en formato legible por máquina	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.040.subfield.b	Lenguaje de la catalogación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.040.subfield.e	Fuentes convencionales de descripciones de datos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.040.subfield.d	Agencia que alteró el registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.040.subfield.a	Código de la agencia catalogadora	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.title.searches_by_date	Informe de Total de Búsquedas por Período	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	error.runtime_error	Error inesperado durante la ejecución de la tarea	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.field.subtitle	Títulos paralelos/subtítulo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.success.save	Proveedor incluido con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.045.indicator.1	Tipo de período cronológico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.administration_backup	Realizar copia de seguridad de la base de datos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.form.hidden_subfields_plural	Exhibir {0} subcampos ocultos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.reservation.page_help	<p>Para realizar una reserva usted deberá seleccionar el lector para el cual la reserva será realizada y, en seguida, seleccionar el registro que será reservado. La búsqueda por el lector puede hacerse por nombre, matrícula u otro campo previamente registrado. Para encontrar el registro, realice una búsqueda similar a la búsqueda bibliográfica.</p>\n<p>Los cancelamientos pueden hacerse seleccionando el lector que posee la reserva.</p><p>La duración de la reserva se calcula de acuerdo con el tipo de usuario, configurado por el menú <strong>Administración</strong> y definido durante el registro del lector.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.users_with_pending_fines	Listar solo Usuarios con multas pendientes	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.confirm_delete_record_title	Excluir registro de proveedor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.acquisition	Informe de Pedidos de Adquisición Efectuados Por Período	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.button.search	Buscar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.confirm_delete_record.forever	Tanto el Login del Usuario como sus permisos serán excluidos permanentemente del sistema y no podrán ser recuperados.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.return_success	Ejemplar devuelto con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.search_count	{current} / {total}	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.description.administration.z3950.server.active	Esta configuración indica si el servidor z39.50 Lugar estará activo. En los casos de instalaciones multi-biblioteca, el nombre de la Colección del servidor z39.50 será igual al nombre de cada biblioteca. Por ejemplo, el nombre de la colección para esta instalación es "{0}".	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.printer_type.printer_80_columns	Impresora 80 columnas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configurations.error.invalid	El valor especificado para una de las configuraciones no es válido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.search_z3950	Distribuida	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.400	Otra forma de nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.user.name_or_id	Nombre o Matrícula	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.error.start_less_than_or_equals_end	El Número inicial debe ser menor o igual al Número final	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.users.success.update	Usuario guardado con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.user.field	Campo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.title	Copia de Seguridad (Backup)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.error.invalid_marc	Falla al leer el Registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.vocabulary.confirm_cancel_editing_title	Cancelar edición de registro de vocabulario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.no_fines	Este usuario no posee multas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.410	Otra forma de nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.button.generate_report	Emitir Informe	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.110.subfield.d	Fecha de la realización del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.110.subfield.c	Lugar de realización del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.110.subfield.b	Unidades subordinadas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.holding.confirm_cancel_editing.2	Todas las alteraciones se perderán	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.accession_number	Sello Patrimonial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.holding.confirm_cancel_editing.1	¿Usted desea cancelar la edición de este registro de ejemplar?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.accesscards.return.success	Tarjeta devuelta con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.title	Importación de Registros	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.110.subfield.l	Lenguaje de texto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.in_this_library	En esta biblioteca	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.110.subfield.n	Número de la parte sección de la obra orden del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.holding.confirm_delete_record.trash	Será movido para la base de datos "papelera de reciclaje"	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.usertype.confirm_delete_record_question.forever	¿Usted realmente desea excluir este Tipo de Usuario?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.users.success.delete	Usuario excluido permanentemente	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	label.logout	Salir	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.field.quotation	Cotización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.field.requisition_select	Seleccione una Solicitud	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.title.holdings	Informe de Sello Patrimonial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	warning.create_backup	Hace más de 3 días que usted está sin generar una copia de seguridad (backup)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	multi_schema.manage.new_schema.field.schema	Atajo de la Biblioteca	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.user.remove_item_button	Excluir	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.110.subfield.a	Nombre de la entidad o del lugar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.user_status	Situación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.580	Nota de Enlace	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.740.subfield.a	Título adicional - Título analítico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.indicator.1.1	Generar nota y entrada secundaria de título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.indicator.1.0	Generar nota, no generar entrada secundaria de título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.usertype.confirm_delete_record_title.forever	Excluir Tipo de Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.acquisition_quotation_delete	Excluir registro de cotización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.switch_to	Cambiar para	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.indicator.1.3	No generar nota, generar entrada secundaria de título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.indicator.1.2	No generar nota ni entrada secundaria de título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.error.psql_not_found	PSQL no encontrado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.common.digital_files	Archivos Digitales	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.740.subfield.n	Número de la parte - Sección de la obra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.dewey	Estadística por Clasificación Dewey	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.740.subfield.p	Nombre de la parte - Sección de la obra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.confirm_delete_record.trash	Será movido para la base de datos "papelera de reciclaje"	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.labels.page_help	<p>El módulo <strong>"Impresión de Etiquetas"</strong> permite generar las etiquetas de identificación interna y de lomo para los ejemplares de la biblioteca.</p>\n<p>Es posible Generar las etiquetas de uno o más ejemplares en una única impresión, utilizando la búsqueda abajo. Este atento al detalle de que el resultado de esta búsqueda es una lista de ejemplares y no de registros bibliográficos.</p>\n<p>Luego de encontrar el(los) ejemplar(es) de interés, use el botón <strong>"Seleccionar ejemplar"</strong> para agregarlos a la lista de impresión de etiquetas. Usted podrá hacer diversas búsquedas, sin perder la selección hecha anteriormente. Cuando finalmente este satisfecho con la selección, cliquee en el botón <strong>"Imprimir etiquetas"</strong>. Será posible seleccionar cual modelo de la hoja de etiquetas se utilizará y en qué posición iniciar.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.024.indicator.1.2	International Standard Music Number (ISMN)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.024.indicator.1.0	International Standard Recording Code/ (ISRC)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.receipt.accession_number	Sello Patrimonial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.access_control.user_has_no_card	No hay tarjeta asociada a este usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.date_to	a	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.deleted	Excluido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.in_these_libraries	En estas bibliotecas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	multi_schema.configuration.title.general.title	Nombre de este Grupo de Bibliotecas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.field.author	Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.cataloging_import	Importación de Registros	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.590	Notas locales	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.yes	Sí	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.595	Notas para inclusión en bibliografías	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.translations.download.title	Descargar archivo de idioma	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.button.import_this_record	Importar este registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.status.in_use_and_blocked	En uso y bloqueado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.lendings_late	Total de Libros atrasados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.confirm_delete_record_question	¿Usted realmente desea excluir este registro de proveedor?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.button.select_item	Seleccionar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.450.subfield.a	Término tópico no usado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.users.error.save	Falla al inscribir al Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.342.indicator.2	Dimensiones de referencia geoespacial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.580.subfield.a	Nota de Enlace	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.342.indicator.1	Dimensiones de referencia geoespacial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.user_returned_lendings	Historial de Devoluciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.administration_z3950_search	Listar servidores z3950	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	login.password.success	Contraseña alterada con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.830.indicator.2.9	9 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.830.indicator.2.8	8 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	label.password	Contraseña	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_cards.button.select_item	Seleccionar usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.confirm_delete_record.forever	Será excluido permanentemente del sistema y no podrá ser recuperado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.select_marc_field	Seleccione un campo Marc	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.simple_search	Búsqueda Bibliográfica Simplificada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.receipt.holding_id	Nro. Registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.830.indicator.2.2	2 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.form.repeat	Repetir	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.830.indicator.2.3	3 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.830.indicator.2.0	Ningún carácter a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.830.indicator.2.1	1 carácter a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.830.indicator.2.6	6 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.confirm_cancel_editing_title	Cancelar edición de registro bibliográfico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.830.indicator.2.7	7 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.830.indicator.2.4	4 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.830.indicator.2.5	5 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.750.subfield.a	Término tópico adoptado en el tesauro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.title.topographic	Informe Topográfico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.user_status.pending_issues	Posee pendencias	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.error.no_records_found	Ningún registro encontrado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.receipt.returns	Devoluciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.today	Hoy	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.lendings	Informe de Préstamos por Período	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.vocabulary_360	Término Asociado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	error.form_invalid_values	Fueron encontrados errores en el rellenado del formulario abajo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.automatic_holding_title	Ejemplares Automáticos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.user	Informe por Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	field.error.max_length	Este campo debe poseer como máximo {0} caracteres	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.110.indicator.1	Forma de entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.555	Nota de Índice Acumulativo o Remisivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.isbn	ISBN	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.status.blocked	Bloqueado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.inactive_users_only	Listar solo Usuarios inactivos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.reinstall.button	Ir a la pantalla de restauración y reconfiguración	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configurations.page_help	<p>La rutina de Configuraciones permite la configuración de diversos parámetros utilizados por el Biblivre, como por ejemplo el Título de la Biblioteca, el Idioma Estándar o la Moneda a ser utilizada. Cada configuración posee un texto explicativo para facilitar su utilización.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.title.lendings_by_date	Informe de Préstamos por Período	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.last_backup	Último Backup	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.edit	Editar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.550	TG (Término genérico)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_243	Título uniforme colectivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.delete	Excluir	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.indicator.2.2	Numeración alternada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.360	Remisiva VT (ver también) y TA (Término relacionado o asociado)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	warning.change_password	Usted todavia no modificó la contraseña estándar de administrador	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.total	Total	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_240	Título uniforme	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.indicator.2.1	Numeración primaria	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.indicator.2.0	No numerada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.525	Nota de Suplemento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.button.print_return_receipt	Imprimir recibo de devolución	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_cards.popup.description	Seleccione en qué etiqueta desea iniciar la impresión	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.error.delete	Falla al excluir la Solicitud	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.521	Notas de público meta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.administration_accesscards_list	Listar tarjetas de acceso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.024.indicator.1	Tipo de número o código normalizado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_245	Título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.520	Notas de resumen	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.250.subfield.b	Información adicional	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.user_type.error.type_has_users	Este Tipo de Usuario posee Usuarios registrados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.250.subfield.a	Indicación de la edición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.user_type.error.delete	Falla al excluir el Tipo de Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.210.indicator.2._	Título llave abreviado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.add_multiple_cards	Registrar Secuencia de Tarjetas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.page_help	<p>La búsqueda bibliográfica permite recuperar informaciones sobre los registros del acervo de esta biblioteca, enlistando sus ejemplares, campos catalográficos y archivos digitales.</p>\n<p>La forma más simple es usar la <strong>búsqueda simplificada</strong>, que tratará de encontrar cada uno de los términos digitados en los siguientes campos: <em>{0}</em>.</p>\n<p>Las palabras son buscadas en su forma completa, pero es posible usar el caracter asterisco (*) para buscar por palabras incompletas, de modo que la búsqueda <em>'brasil*'</em> encuentre registros que contengan <em>'brasil'</em>, <em>'brasilia'</em> y <em>'brasilero'</em>, por ejemplo. Los pares de comillas pueden ser usados para encontrar dos palabras en secuencia, de modo que la búsqueda <em>"mi amor"</em> encuentre registros que contengan las dos palabras juntas, pero no encuentre registros con el texto <em>'mi primer amor'</em>.</p>\n<p>La <strong>búsqueda avanzada</strong> otorga un mayor control sobre los registros localizados, permitiendo, por ejemplo, buscar por fecha de catalogación o exactamente en el campo deseado.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.error.invalid_photo_extension	La extensión del archivo seleccionado no es válida para la foto del usuario. Use archivos .png, .jpg, .jpeg o .gif	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.541.indicator.1._	ninguna información suministrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.database.private_full	Base Privada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.534	Notas de facsímile	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.creation_date	Fecha Inclusión;	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.530	Notas de disponibilidad de forma física	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.750	Término tópico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.indicator.2._	Ninguna información suministrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.labels.popup.description	Seleccione en cuál etiqueta desea iniciar la impresión	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.reservation.button.delete	Excluir	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tabs.form	Formulario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.vocabulary.page_help	<p>La búsqueda de vocabulario permite recuperar informaciones sobre los términos presentes en el acervo de esta biblioteca, caso catalogados.</p>\n<p>La búsqueda tratará de encontrar cada uno de los términos digitados en los siguientes campos: <em>{0}</em>.</p>\n<p>Las palabras son buscadas en su forma completa, pero es posible usar el carácter asterisco (*) para buscar por palabras incompletas, de modo que la búsqueda <em>'brasil*'</em> encuentre registros que contengan <em>'brasil'</em>, <em>'brasilia'</em> y <em>'brasilero'</em>, por ejemplo. Los pares de comillas pueden ser usados para encontrar dos palabras en secuencia, de modo que la búsqueda <em>"mi amor"</em> encuentre registros que contengan las dos palabras juntas, pero no encuentre registros con el texto <em>'mi primer amor'</em>.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.show_all	Mostrar todos los {0} backups	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.field.response_date	Fecha de Llegada de la Cotización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.title.bibliography	Informe de Bibliografía por Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.field.author_title	Título y otras palabras asociadas al nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_260	Imprenta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.simple_search	Búsqueda Simplificada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.cataloging_bibliographic_delete	Excluir registro bibliográfico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permission.success.delete	Login excluido con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.500	Notas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.501	Notas iniciadas con la palabra "con"	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.502	Notas de disertación o tesis	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.504	Notas de bibliografía	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.505	Notas de contenido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.administration_password	Cambio de Contraseña	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.541.indicator.1.1	no confidencial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.541.indicator.1.0	confidencial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.buttons.apply_fine	Multar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lendings.holding_list_lendings	Listar solamente ejemplares prestados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_250	Edición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.datafield	Campo MARC	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_255	Escala	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_256	Características del archivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_257	Lugar de producción	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.success.update	Cotización guardada con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_258	Información sobre el material	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.location	Localización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_field.photo	Foto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	login.error.empty_login	El campo login no puede estar vacío	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.515	Nota de Peculiaridad en la Numeración	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.selected_records_plural	{0} registros seleccionados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.clear_search	Limpiar términos de la búsqueda	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.biblio	Bibliográficos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.backup_not_complete	Backup no terminado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.error.no_supplier_found	No fue posible encontrar ningún proveedor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.confirm_cancel_editing_title	Cancelar edición de registro de cotización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.users.success.disable	Éxito al marcar usuario como inactivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	digitalmedia.error.file_not_found	El archivo especificado no fue encontrado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.error.delete	Falla al exluir la cotización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	warning.fix_now	Resolver este problema	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.holding.availability.available	Disponible	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.confirm_delete_record_title	Excluir registro bibliográfico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.holding.availability	Disponibilidad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.status.available	Disponible	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.address_city	Ciudad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	login.error.empty_new_password	El campo "nueva contraseña" no puede estar vacío	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.return_date	Fecha de la devolución	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.subfield.c	Indicación de responsabilidad de la obra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.subfield.a	Título principal	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.cataloging_vocabulary_move	Mover registro de vocabulario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.subfield.b	Títulos paralelos/subtítulos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.biblivre4restore.confirm_title	Restaurar Backup	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.receipt.author	Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.subfield.p	Nombre de la parte - sección de la obra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.email	Email	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.field.country	País	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.subfield.n	Número de la parte - sección de la obra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.111.indicator.1.0	nombre invertido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.multi_schema_configurations	Configuraciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.111.indicator.1.1	nombre de la jurisdicción	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.subfield.h	Medio	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.circulation_reservation_list	Listar reservas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.111.indicator.1.2	nombre en orden directo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.cataloging_bibliographic_move	Mover registro bibliográfico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.type.biblio	Registro bibliográfico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.change_status.cancel	La Tarjeta será cancelada y estará indisponible para su uso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_status.blocked	Bloqueado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.order	Ordenar por	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configurations.error.file_not_found	Archivo no encontrado.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.source_search_title	Importar registros a partir de una búsqueda Z39.50	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.reservation.expiration_date	Fecha de expiración de la reserva	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.field.state	Estado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.title.general.subtitle	Subtítulo de la biblioteca	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.upload_popup.uploading	Enviando archivo...	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.error.save	Falla al guardar el proveedor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.670.subfield.a	Nota de origen del Término	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.upload_popup.title	Abriendo Archivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.database.main_full	Base Principal	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.page_help	<p>La rutina de Pedidos permite el registro y búsqueda de pedidos (compras) realizados con los proveedores registrados. Para registrar un nuevo Pedido, se debe seleccionar un Proveedor y una Cotización previamente registrados, así como entrar datos tales como Fecha de Vencimiento y datos de la Factura.</p>\n<p>La búsqueda tratará de encontrar cada uno de los términos digitados en los campos <em>Número de Registro de Pedido, Nombre de Fantasía del Proveedor, y Autor o Título de la Solicitud</em>.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.555.subfield.3	Materiales especificados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.title.general.multi_schema	Habilitar Multibibliotecas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.error.couldnt_restore_backup	No fue posible restaurar el backup seleccionado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.administration_configurations	Administrar configuraciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.holdings_available	Disponibles	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.group.custom	Informe Personalizado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.biblio_reservation	Reservas por registro bibliográfico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.acquisition_request_save	Guardar registro de requerimiento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.accesscards.return.error	Falla al devolver la Tarjeta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.fine.failure_pay_fine	Falla al pagar multa	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.indicator.2.2	entrada analítica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.circulation_access	Control de Acceso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.login_change_password	Cambiar contraseña	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.210	Título Abreviado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.multi_schema_manage	Gerencia de Bibliotecas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.856.subfield.y	Link en texto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	field.error.date	El valor rellenado no tiene una fecha válida. Utilice el formato {0}	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.856.subfield.u	URI	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.accesscards.lend.error	Falla al vincular la Tarjeta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_field.login	Login	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.856.subfield.d	Camino	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.upload_popup.processing	Procesando...	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.555.subfield.a	Nota de índice acumulativo y remisivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	multi_schema.manage.new_schema.field.title	Nombre de la biblioteca	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.555.subfield.b	Fuente disponible	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_status.active	Activo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.z3950.success.update	Servidor z39.50 actualizado con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.856.subfield.f	Nombre del archivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.555.subfield.c	Grado de control	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.555.subfield.d	Referencia bibliográfica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.accession_number.full	Informe completo de Sello Patrimonial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.reserved.warning	Todos los ejemplares disponibles de este registro están reservados para otros lectores. El préstamo puede ser efectuado, sin embargo verifique las informaciones de reservas.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.321.subfield.b	Fechas de la periodicidad anterior	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.phone_cel	Celular	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.321.subfield.a	Periodicidad Anterior	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.type.authorities	Autoridades	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.555.subfield.u	Identificador uniforme de recursos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	multi_schema.manage.new_schema.button.create	Crear Biblioteca	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.searches	Informe de Total de Búsquedas por Período	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.open_item_button	Abrir registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.administration_configurations	Configuraciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.041.indicator.1.0	El ítem no es y no incluye traducción	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.tabs.reservations	Reservas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.cancel	Cancelar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	field.error.min_length	Este campo debe poseer como mínimo {0} caracteres	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
pt-BR	circulation.user_field.short_type	Tipo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
es	marc.bibliographic.datafield.041.indicator.1.1	El ítem es e incluye traducción	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.indicator.2._	ninguna información suministrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.distributed.isbn	ISBN	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.cataloging_labels	Impresión de Etiquetas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.option.title	Título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_cards.page_help	<p>El módulo <strong>"Impresión de Carnets"</strong> permite Generar las etiquetas de identificación de los lectores de la biblioteca.</p>\n<p>Es posible generar los carnets de uno o más lectores en una única impresión, utilizando la búsqueda abajo.</p>\n<p>Luego de encontrar el(los) lector(es), use el botón <strong>"Seleccionar usuario"</strong> para agregarlos a la lista de impresión de carnets. Usted podrá realizar diversas búsquedas, sin perder la selección hecha anteriormente. Cuando este satisfecho con la selección, cliquee en el botón <strong>"Imprimir carnets"</strong>. Será posible seleccionar la posición del primer carnet en la hoja de etiquetas.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.circulation_save	Guardar registro de usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.field.info	Observaciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.no_attachments	Este registro no posee archivos digitales	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.750.subfield.z	Subdivisión geográfica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.error.save	Falla al guardar la Solicitud	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.750.subfield.x	Subdivisión general	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.505.subfield.a	Notas de contenido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.750.subfield.y	Subdivisión cronológica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.holding.confirm_delete_record_title	Excluir registro de ejemplar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.button.print_lending_receipt	Imprimir recibo de préstamo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.field.quotation_date	Fecha del Pedido de Cotización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.100.indicator.1	Forma de entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.lending.error.holding_is_lent	El ejemplar seleccionado ya está prestado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.database.trash	Papelera de Reciclaje	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.lendings_top	Libros más prestados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.field.address_number	Número	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.field.id	N&ordm; del registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.250	Edición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.255	Dato matemático cartográfico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.256	Características del archivo de computadora	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.750.indicator.2.0	Library of Congress Subject Heading	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.obs	Observaciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.help	Ayuda	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.258	Información sobre material filatélico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.257	País de la entidad productora	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.material_type.articles	Artículo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.user_not_found	No fue posible encontrar el usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.150.subfield.y	Subdivisión cronológica adoptada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.150.subfield.x	Subdivisión general adoptada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.750.indicator.2.4	Source not specified	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.title.unit_value	Valor Unitario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.lending.error.holding_unavailable	El ejemplar seleccionado no está disponible para préstamos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.150.subfield.z	Subdivisión geográfica adoptada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.indexing_groups.author	Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.button_full	Crear backup completo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.start_number	Número inicial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240	Título uniforme	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243	Título Convencional Para Archivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245	Título principal	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.database_work	Trabajo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246	Forma Variante de Título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.user_lendings	Préstamos Activos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.page_help	<p>La rutina de Cotizaciones permite el registro y búsqueda de cotizaciones (presupuestos) realizadas con los proveedores registrados. Para registar una nueva Cotización, se debe seleccionar un Proveedor y una Solicitud previamente registrados, así como entrar datos como el valor y la cantidad de obras cotizadas.</p>\n<p>La búsqueda tratará de encontrar cada uno de los términos digitados en los campos <em>Número de Registro de Cotización o Nombre Fantasía del Proveedor</em>.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.accesscards.bind_card	Vincular Tarjeta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.description.search.distributed_search_limit	Esta configuración representa la cantidad máxima de resultados que serán encontrados en una búsqueda distribuida. Evite el uso de límite muy elevado pues las búsquedas distribuidas llevarán mucho tiempo para volver a los resultados encontrados.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.confirm_delete_record_question.forever	¿Usted realmente desea excluir este registro de proveedor?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.success.update	Tarjeta guardada con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.circulation_user_reservation	Reservas del Lector	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.856.subfield.u	URI	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	text.multi_schema.select_library	Lista de Bibliotecas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.publication_year	Año de publicación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.856.subfield.y	Link en el texto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.printer_type.printer_40_columns	Impresora 40 columnas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.no_backups_found	Ningún backup encontrado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.856.subfield.d	Camino	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.circulation_delete	Excluir registro de usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.515.subfield.a	Nota de Peculiaridad en la Numeración	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.856.subfield.f	Nombre del archivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.user_type.field.name	Tipo de Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.949	Sello patrimonial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.947	Información de la Colección	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.611.indicator.1	Forma de entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.groups.circulation	Circulación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.150.subfield.a	Término tópico adoptado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.button.move_records	Mover Registros	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.holding.accession_number	Sello patrimonial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.150.subfield.i	Calificador	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.payment_date	Fecha de Pago	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_field.status	Situación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.error.no_valid_terms	La búsqueda especificada no contiene términos válidos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.circulation_print_user_cards	Imprimir carnets	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.users_with_late_lendings	Listar solo Usuarios con préstamos en atraso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.field.delivered_quantity	Cantidad recibida	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.title.holdings_full	Informe completo de Sello Patrimonial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.111.indicator.1	Forma de entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.field.created_by	Responsable	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_130	Obra Anónima	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	language_name	Español (Internacional)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.page_help	<p>Para realizar un préstamo usted deberá seleccionar el lector para el cual el préstamo será realizado y, en seguida, seleccionar el ejemplar que será prestado. La búsqueda por el lector puede ser hecha por nombre, matrícula u otro campo previamente registrado. Para encontrar el ejemplar, utilize su Sello Patrimonial.</p><p>Las devoluciones pueden ser hechas a través del lector seleccionado o directamente por el Sello Patrimonial del ejemplar que está siendo devuelto o renovado.</p><p>El plazo para la devolución se calcula de acuerdo con el tipo de usuario, configurado por el menu <strong>Administración</strong> y definido durante el registro del lector.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.user_type.field.fine_value	Valor de la Multa por atrasos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.distributed_search	Búsqueda Distribuida	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.cataloging_authorities	Autoridades	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.acquisition_quotation_list	Listar cotizaciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_cards.paper_description	{paper_size} {count} etiquetas ({height} mm x {width} mm)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.fieldset.order	Ordenación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.selected_records_plural	{0} Valores Agregados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.670.subfield.b	Información encontrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.670.subfield.a	Nombre retirado de	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
pt-BR	circulation.lending.button.renew	Renovar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
es	marc.bibliographic.datafield.700.indicator.2	Tipo de entrada secundaria	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.700.indicator.1	Forma de entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_field.short_type	Tipo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.indicator.1.2	2 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.indicator.1.3	3 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.indicator.1.0	Ningún caracter a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.indicator.1.1	1 carácter a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.indicator.1.6	6 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.indicator.1.7	7 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.indicator.1.4	4 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.indicator.1.5	5 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.holding.availability.unavailable	No disponible	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.group.circulation	Circulación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.title.author	Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.indicator.1.8	8 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.title	Título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.indicator.1.9	9 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.field.delivery_time	Plazo de entrega (Prometido)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.description.general.currency	Esta configuración representa la moneda que será utilizada en multas y en el módulo de adquisición.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.database_main	Principal	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.record.success.move	Registros movidos con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.acquisition_quotation	Cotizaciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.holding.availability	Disponibilidad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.reservation.delete_success	Reserva excluida con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.029.subfield.a	Número de ISMN	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.created_between	Catalogado entre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.confirm_delete_record_title.forever	Excluir registro de cotización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.260	Publicación, edición. Etc.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.confirm_delete_record_question.forever	¿Usted realmente desea excluir este registro de Pedido?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.fieldset.title.values	Valores	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.confirm_delete_record.forever	Será excluido permanentemente del sistema y no podrá ser recuperado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.913	Código Lugar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.simple_term_title	Rellene los términos de la búsqueda	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.reindex.title	Reindización de la Base de Datos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.lending.error.blocked_user	El lector seleccionado está bloqueado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.records_found_singular	{0} registro encontrado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.710.indicator.2._	ninguna información suministrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.error.delete	Falla al excluir el proveedor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.type.do_not_import	No importar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.indicator.1	Número de caracteres a ser despreciados en la alfabetización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.indicator.2	Tipo de entrada secundaria	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.error.delete.user_has_accesscard	Este usuario posee tarjeta de acceso en uso.  Realice la devolución de la tarjeta antes de excluir este usuario.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_534	Notas de facsímil	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.360.subfield.z	Subdivisión geográfica adoptada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.360.subfield.y	Subdivisión cronológica adoptada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.confirm_delete_record_title	Excluir registro de Pedido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.360.subfield.x	Subdivisión general adoptada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.upload_popup.uploading	Enviando archivo...	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.reservations	Informe de Reservas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.reservation_date	Fecha de la Reserva	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.vocabulary.term.up	Término Use Para (UP)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_520	Notas de resumen	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.411.subfield.a	Nombre del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_521	Notas de público meta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.title.quantity	Cantidad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.multi_schema	Multibibliotecas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.page_help	<p>La rutina de Informes permite la generación e impresión de diversos Informes puestos a disposición por el Biblivre. Los Informes disponibles se dividen entre las rutinas de Adquisición, Catalogación y Circulación.</p>\n<p>Algunos de los Informes disponibles poseen filtros, como Base Bibliográfica, o Período, por ejemplo. Para otros, basta seleccionar el Informe y cliquear en "Emitir Informe".</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_110	Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.tabs.form	Registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_111	Autor Evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.100.indicator.1.1	apellido simple o compuesto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.100.indicator.1.2	apellido compuesto (anticuado)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.100.indicator.1.3	nombre de la familia	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	multi_schema.configurations.page_help	La rutina de Configuraciones de Multi-bibliotecas permite alterar configuraciones globales del grupo de bibliotecas y configuraciones estándar que serán usadas por las bibliotecas registradas. Todas las configuraciones marcadas con un asterisco (*) serán usadas como estándar en nuevas bibliotecas registradas en este grupo, pero pueden ser alteradas internamente por los administradores, a través de la opción <em>"Administración"</em>, <em>"Configuraciones"</em>, en el menú superior.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.holdings_count	Cantidad de Ejemplares	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.clear	Limpiar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.100.indicator.1.0	nombre simple o compuesto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.selected_records_singular	{0} Valor Agregado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.vocabulary.term.tg	Término General (TG)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.vocabulary.term.te	Término Específico (TE)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.preview	Pre visualización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.vocabulary.confirm_delete_record_title	Excluir registro de vocabulario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.490	Indicación de serie	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.vocabulary.term.ta	Término Asociado (VT / TA)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.search	Búsqueda	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.modified	Actualizado en	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.521.subfield.a	Notas de público meta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.phone_home	Teléfono Residencial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.unclassified	<No clasificado>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.administration_translations	Administrar traducciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.600.indicator.1	Forma de entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.501.subfield.a	Notas iniciadas con la palabra "con"	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.260.subfield.b	Nombre del editor, publicador, etc.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.260.subfield.c	Fecha de publicación, distribución, etc.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.user.search	Digite el nombre o matrícula del Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.260.subfield.e	Nombre del impresor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.error.invalid_search_parameters	Los parámetros de esta búsqueda no están correctos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.author_type.select_author_type	Seleccione el tipo de autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.title.search.results_per_page	Resultados por página	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.database.private	Privado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.260.subfield.a	Lugar de publicación, distribución, etc.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	error.biblivre_is_locked_please_wait	Este Biblivre está en mantenimiento. Por favor, intente nuevamente en algunos minutos.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_500	Notas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.confirm_delete_record.trash	Será movido a la base de datos "papelera de reciclaje"	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.260.subfield.f	Información adicional	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_502	Nota de tesis	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.260.subfield.g	Fecha de impresión	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_505	Notas de contenido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_504	Notas de bibliografía	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_506	Notas de acceso restricto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.circulation_lending_list	Listar préstamos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.520.subfield.a	Notas de resumen	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.reservation.record_reserved_to_the_following_readers	Este registro está reservado para los siguientes lectores	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.change_password.new_password	Nueva contraseña	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	login.error.password_not_matching	Los campos "nueva contraseña" y "repita la nueva contraseña" deben ser iguales	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.110.subfield.b	Unidades subordinadas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.110.subfield.c	Lugar de realización del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.110.subfield.d	Fecha de la realización del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.subject	Asunto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configurations.save.success	Configuraciones alteradas con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	z3950.adresses.list.no_address_found	Ningún Servidor Z39.50 encontrado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.110.subfield.l	Idioma del texto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.search_limit	La búsqueda realizada encontró {0} registros, no obstante solamente los {1} primeros serán exhibidos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.110.subfield.n	Número de la parte - sección de la obra - orden del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.error.generate	Falla al Generar el Informe. Verifique el rellenado del formulario.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.button.renew	Renovar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.record.error.save	Falla al guardar el Registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_100	Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.user.open_item_button	Abrir registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.users.success.unblock	Usuario desbloqueado con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.vocabulary.simple_search	Búsqueda de Vocabulario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.110.subfield.a	Nombre de la entidad o del lugar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.error.unblock	Falla al desbloquear la Tarjeta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.acquisition_order_delete	Excluir registro de pedido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.confirm_cancel_editing.2	Todas las alteraciones se perderán	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.ok	Ok	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.confirm_cancel_editing.1	¿Usted desea cancelar la edición de este registro de solicitud?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.biblivre4restore.button	Restaurar backup seleccionado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.vocabulary.indexing_groups.total	Total	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.authorities_670	Nombre retirado de	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.z3950.confirm_cancel_editing_title	Cancelar edición del Servidor Z39.50	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.field_count	Recuento del campo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.362.indicator.1.1	Nota no formateada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.error.invalid_file	Archivo inválido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.362.indicator.1.0	Estilo formateado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.no	No	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.search_button	Buscar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.z3950.confirm_cancel_editing.2	Todas las alteraciones se perderán	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.z3950.confirm_cancel_editing.1	¿Usted desea cancelar la edición de este Servidor Z39.50?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.biblivre4restore.success	Restauración de Backup	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.circulation_access_control_bind	Administrar control de acceso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.confirm_cancel_editing.1	¿Usted desea cancelar la edición de este registro de proveedor?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.cataloging_print_labels	Imprimir etiquetas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.080.subfield.2	Número de edición de la CDU	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.610.indicator.1.0	nombre simple o compuesto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.confirm_cancel_editing.2	Todas las alteraciones serán perdidas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.610.indicator.1.3	nombre de familia	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_cards.popup.title	Formato de las etiquetas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.610.indicator.1.1	apellido simple o compuesto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.610.indicator.1.2	apellido compuesto (obsoleto)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.reindex.button_authorities	Reindizar base de autoridades	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.option.author	Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.authorities.simple_search	Búsqueda de Autoridades	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.520.subfield.u	URI	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.user_current_lending_list	Ejemplares prestados a este lector	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.210.subfield.b	Calificador	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.210.subfield.a	Título Abreviado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.255.subfield.a	Escala	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.cataloging_label	Etiquetas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.vocabulary_680	Nota sobre Alcance	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_700	Autor secundario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.vocabulary_685	Nota de Historial o Glosario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.clean_install	Nueva Biblioteca	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.acquisition_order_list	Listar pedidos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.migration.groups.access_control	Tarjetas de acceso y Control de acceso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.distributed.query_placeholder	Rellene los términos de la búsqueda	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.distributed.any	Cualquier	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.user_type.field.description	Descripción	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.accesscards.lend.success	Tarjeta vinculada con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.change_status.title.unblock	Desbloquear Tarjeta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.button.inactive	Marcar como inactivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.740.indicator.1	Número de caracteres a ser despreciados en la alfabetización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.740.indicator.2	Tipo de entrada secundaria	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	multi_schema.manage.error.description	Falla al crear nueva biblioteca	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.topographic	Informe Topográfico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.title.title	Título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.translations.upload_popup.processing	Procesando...	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.vocabulary.indexing_groups.up_term	Término Use Para (UP)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.750.indicator.2.4	Source not specified	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.select_item_button	Seleccionar registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.button.block	Bloquear	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.reindex.button_vocabulary	Reindizar base de vocabulario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.400	Otra Forma de nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.administration_accesscards_delete	Excluir tarjetas de acceso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.translations.download.field.languages	Idioma	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.error.block	Falla al bloquear Tarjeta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.100.subfield.d	Fechas asociadas al nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.vocabulary_670	Orígen de las Informaciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.100.subfield.c	Título y otras palabras asociadas al nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.410	Otra Forma de nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.tabs.fines	Multas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.100.subfield.q	Forma completa de nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.expected_date	Fecha prevista	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.success.delete	Tarjeta excluida con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.button.unavailable	No disponible	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.630.indicator.1	Número de caracteres a ser despreciados en la alfabetización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	digitalmedia.error.file_could_not_be_saved	El archivo enviado no puede ser guardado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.user_id	Matrícula	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.411	Otra Forma de nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.750.indicator.2.0	Library of Congress Subject Headings	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.100.subfield.a	Apellido y/o nombre del autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.100.subfield.b	Numeración que sigue al nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_590	Notas locales	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.biblivre4restore.field.upload_file	Seleccionar archivo de backup	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.600.indicator.1.0	nombre simple o compuesto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.daily_fine	Multa diaria	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.600.indicator.1.1	apellido simple o compuesto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.600.indicator.1.2	apellido compuesto (obsoleto)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.600.indicator.1.3	nombre de familia	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.advanced_search	Búsqueda Avanzada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.description.general.title	Esta configuración representa el nombre de la biblioteca, que será exhibido al inicio de las páginas del Biblivre y en los informes.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.label_full	Backup completo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.title.search.result_limit	Límite de resultados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.gender	Género	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.empty_lending_list	Este lector no posee ejemplares prestados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.acquisition_supplier	Proveedores	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.access_control.card_not_found	Tarjeta no encontrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.multi_schema_backup	Backup y Restauración	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.usertype.confirm_cancel_editing_title	Cancelar edición del Tipo de Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.confirm_cancel_editing_title	Cancelar inclusión de Tarjetas de Acceso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.distributed.no_servers	No es posible realizar una búsqueda Z39.50 pues no existen bibliotecas remotas registradas. Para solucionar este problema, registre los servidores Z39.50 de las bibliotecas de interés en la opción <em>"Servidores Z39.50"</em> dentro de <em>"Administración"</em> en el menu superior. Para esto es necesario un nombre de <strong>usuario</strong> y <strong>contraseña</strong>.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.editor	Editora	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.source_file_title	Importar registros a partir de un archivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.indexing_groups.year	Año	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.groups.digitalmedia	Medio Digital	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.user_type.field.reservation_limit	Límite de reservas simultáneas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.users.failure.unblock	Falla al desbloquear al Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.field.expiration_date	Fecha de Validez de la Cotización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.change_password.submit_button	Cambiar contraseña	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.database.work	Trabajo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.indicator.2	Número de caracteres a ser despreciados en la alfabetización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.reader	Lector	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.automatic_holding.holding_acquisition_date	Fecha de adquisición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.indicator.1	Genera entrada secundaria en la ficha	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.users.failure.block	Falla al bloquear al Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.450	UP (remisiva para TE no usado)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.045.subfield.b	Período de tiempo formateado de 9999 a.C en adelante	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.045.subfield.a	Código del período de tiempo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	digitalmedia.error.no_file_uploaded	Ningún archivo fue enviado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.045.subfield.c	Período de tiempo formateado anterior a 9999 a.C.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.210.indicator.2.0	Otro título abreviado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.days_late	Días de atraso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.error.order_not_found	No fue posible encontrar el pedido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.holding_lent_to_the_following_reader	Este ejemplar está prestado para el lector abajo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_555	Notas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.650.subfield.a	Asunto tópico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.sort_by	Ordenar por	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.accesscards.unbind_card	Devolver Tarjeta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permission.error.create_login	Error al crear login de usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.210.indicator.1.0	No generar entrada secundaria de título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.z3950.field.collection	Colección	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.button.delete	Excluir	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.migration.migrate.error	Falla al importar los datos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_status.pending_issues	Posee pendencias	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.210.indicator.1.1	Generar entrada secundaria de título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.title	Informes	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.reindex.wait	Dependiendo del tamaño de la base de datos, esta operación podrá demorar. El Biblivre quedará indisponible durante el proceso, que puede durar hasta 15 minutos.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.field.deadline_date	Fecha de Vencimiento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_651	Asunto geográfico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852	Informaciones sobre la localización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_650	Asunto tópico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.option.database.work	Trabajo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.administration	Administración	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.856	Localización de obras por medio electrónico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	login.error.login_already_exists	Este login ya existe. Escoja otro nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.field.requester	Solicitante	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.title	Título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	format.datetime	dd/MM/yyyy HH:mm	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.button.new_holding	Nuevo ejemplar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.field.publisher	Editora	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.error.no_card_found	Ninguna tarjeta encontrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.650.subfield.x	Subdivisión general	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.650.subfield.y	Subdivisión cronológica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.650.subfield.z	Subdivisión geográfica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	login.access_denied	Acceso denegado. Usuario o contraseña inválidos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.reindex.success	Reindización concluida con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.534.subfield.a	Notas de facsímile	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.subfield.p	Nombre de la parte - sección de la obra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.users.success.block	Usuario bloqueado con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.circulation_lending_lend	Realizar préstamos de obras	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.subfield.n	Número de la parte - sección de la obra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.confirm_delete_record_question.forever	¿Usted realmente desea excluir el Login de Usuario?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.411	Otra forma de nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.subfield.l	Idioma del texto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.error.select_reader_first	Para prestar un ejemplar usted precisa, primeramente, seleccionar un lector	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.subfield.k	Subencabezamientos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.indexing_groups.all	Cualquier campo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.labels.button.print_labels	Imprimir etiquetas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.subfield.g	Información adicional	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.subfield.f	Fecha de edición del ítem que está siendo procesado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.year	Año	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.subfield.d	Fecha que aparece junto al título uniforme en la entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.130.subfield.a	Título uniforme	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_630	Asunto título uniforme	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.administration_indexing	Administrar indización de la base de datos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.685.subfield.i	Texto explicativo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.holding.confirm_delete_record.forever	Será excluido permanentemente del sistema y no podrá ser recuperado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.button.save_as_new	Guardar como nuevo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.reservation.reserve_success	Reserva efectuada con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.z3950.page_help	<p>La rutina de Servidores Z39.50 permite el registro y búsqueda de los Servidores utilizados por la rutina de Búsqueda Distribuida. Para realizar el registro serán necesarios los datos de la Colección Z39.50, así como la dirección URL y puerta de acceso.</p>\n<p>Al accesar a esa rutina, el Biblivre listará automáticamente todos los Servidores previamente registrados. Usted podrá entonces filtrar esa lista, digitando el <em>Nombre</em> de un Servidor que quiera encontrar.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.automatic_holding.holding_library	Biblioteca Depositaria	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configurations.error.value_must_be_boolean	El valor de este campo debe ser verdadero o falso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.110.indicator.1.2	nombre en orden directo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.change_password.title	Cambio de contraseña	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	login.error.invalid_password	El campo "contraseña actual" no es compatible con su contraseña	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.confirm_delete_record_question	¿Usted realmente desea excluir este registro de autoridad?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.110.indicator.1.0	nombre invertido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.110.indicator.1.1	nombre de la jurisdicción	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.490.indicator.1.0	Título no desdoblado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.541.subfield.3	Especificaciones del material	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.490.indicator.1.1	Título desdoblado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.590.subfield.a	Notas locales	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.acquisition_request_list	Listar requerimientos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.invalid_pg_dump_path	Camino inválido. El Biblivre no será capaz de generar backups ya que el archivo <strong>pg_dump</strong> no fue encontrado.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.holdings.title	Buscar Ejemplar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.accession_number	Informe de Sello Patrimonial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.description.cataloging.accession_number_prefix	El sello patrimonial es el campo que identifica únicamente un ejemplar. En el Biblivre, la regla de formación para el sello patrimonial depende del año de adquisición del ejemplar, de la cantidad de ejemplares adquiridos en el año y del prefijo del sello patrimonial. Este prefijo es el término que será incluido antes de la numeración de año, en el formato <prefijo>.<año>.<contador> (Ex: Bib.2014.7).	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.confirm_delete_record.forever	Será excluido permanentemente del sistema y no podrá ser recuperado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.111.indicator.1.1	nombre de la jurisdicción	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.111.indicator.1.2	nombre en el orden directo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.111.indicator.1.0	nombre invertido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.previous	Anterior	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.administration_usertype_list	Listar tipos de Usuarios	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_cards.button.select_page	Seleccionar usuarios de esta página	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.administration_user_types	Tipos de Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_610	Asunto entidad colectiva	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_611	Asunto evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select_report	Seleccione un Informe	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.680	Nota de alcance (NE)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.description.general.business_days	Esta configuración representa los días de funcionamiento de la biblioteca y será usada por los módulos de préstamo y reserva. El principal uso de esta configuración es evitar que la devolución de un ejemplar sea marcada para un día en que la biblioteca está cerrada.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.wait	Aguarde	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.users	Usuarios	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.685	Nota de historial o glosario (GLOSS)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.circulation	Circulación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.user_deleted	Usuario excluido del sistema	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.cataloging_bibliographic	Bibliográfica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.fieldset.cataloging	Búsqueda Bibliográfica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.field.supplier_number	CNPJ/CUIT	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.670	Nota de origen del Término	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.reindex.error.invalid_record_type	Tipo de registro en blanco o desconocido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.error.existing_card	La Tarjeta ya existe	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.authorities.page_help	<p>La búsqueda de autoridades permite recuperar informaciones sobre los autores presentes en el acervo de esta biblioteca, caso catalogados.</p>\n<p>La búsqueda tratará de encontrar cada uno de los términos digitados en los siguientes campos: <em>{0}</em>.</p>\n<p>Las palabras son buscadas en su forma completa, pero es posible usar el caracter asterisco (*) para buscar por palabras incompletas, de modo que la búsqueda <em>'brasil*'</em> encuentre registros que contengan <em>'brasil'</em>, <em>'brasilia'</em> y <em>'brasilero'</em>, por ejemplo. Los pares de comillas pueden ser usados para encontrar dos palabras en secuencia, de modo que la búsqueda <em>"mi amor"</em> encuentre registros que contengan las dos palabras juntas, pero no encuentre registros con el texto <em>'mi primer amor'</em>.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.add_field	Agregar Término	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.vocabulary_750	Término Tópico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	login.goodbye	Hasta luego	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.user_type.error.no_user_type_found	Ningún Tipo de Usuario encontrado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.labels.button.select_page	Seleccionar ejemplares de esta página	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.user_type.field.lending_time_limit	Plazo de préstamo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.tabs.lendings	Préstamos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tabs.marc	MARC	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_600	Asunto persona	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.groups.login	Login	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.description.general.subtitle	Esta configuración representa un subtítulo para la biblioteca, que será exhibido al inicio de las páginas del Biblivre, luego abajo del <strong>Nombre de la biblioteca</strong>. Esta configuración es opcional.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.360.subfield.y	Subdivisión cronológica adoptada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.360.subfield.x	Subdivisión general adoptada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.360.subfield.z	Subdivisión geográfica adoptada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.selected_records_singular	{0} Valor Agregado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.material_type.map	Mapa	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.711.subfield.e	Nombre de subunidades del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.711.subfield.g	Informaciones adicionales	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.711.subfield.a	Nombre del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.711.subfield.c	Lugar de realización del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_cards.selected_records_singular	{0} usuario seleccionado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.711.subfield.d	Fecha de realización del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.711.subfield.n	Número de orden del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.711.subfield.k	Subencabezamientos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.fieldset.user	Búsqueda de Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.711.subfield.t	Título de la obra junto a la entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.490.subfield.a	Título de la serie	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.490.subfield.v	Número de volumen o designación secuencial de la serie	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.080.subfield.a	Número de Clasificación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.830.indicator.2	Número de caracteres a ser despreciados en la alfabetización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configurations.error.value_is_required	El rellenado de este campo es obligatorio	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.360.subfield.a	Término tópico adoptado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.field.area	Barrio	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	multi_schema.manage.success.create	Nueva biblioteca creada con éxito.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.success.save	Solicitud incluida con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.indicator.1.3	3 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.indicator.1.2	2 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.group.cataloging	Catalogación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.indicator.1.5	5 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.indicator.1.4	4 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.indicator.1.7	7 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.indicator.1.6	6 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.indicator.1.9	9 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.user_list_by_type	Lista de Usuarios Por Tipo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.reinstall.confirm.title	Ir a la pantalla de restauración y reconfiguración	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.indicator.1.8	8 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.button.import_all	Importar todas las páginas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.registered_between	Registrado entre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.lendings_count	Total de Libros prestados en el período	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.title.reservation	Informe de Reservas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.end_date	Fecha Final	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.indicator.1.1	1 carácter a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.indicator.1.0	Ningún carácter a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.subfield.p	Nombre de la parte - sección de la obra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.clean_install.button	Iniciar como una nueva biblioteca	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.411.subfield.a	Nombre del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.repeat_password	Repetir contraseña	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.confirm_delete_record_title.forever	Excluir registro de Pedido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.help	Ayuda	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.error.you_cannot_delete_yourself	Usted no puede excluirse o marcarse como inactivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.self_circulation	Reservas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.button.list_all	Listar Todos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.indicator.1.0	No genera entrada para el título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.prefix	Prefijo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.indicator.1.1	Genera entrada para el título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.custom_count	Recuento de Registros Bibliográficos por Campo Marc	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	error.invalid_handler	No fue posible encontrar un handler para esta acción	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.containing_text	Conteniendo el texto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.material_type	Tipo de material	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.migration.button.migrate	Importar datos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.expected_return_date	Fecha prevista para devolución	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.indexing_groups.author	Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.041.indicator.1	Indicación de traducción	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.cataloging_vocabulary_delete	Excluir registro de vocabulario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.database.work_full	Base de Trabajo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tabs.holdings	Ejemplares	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.labels.paper_description	{paper_size} {count} etiquetas ({height} mm x {width} mm)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.search_bibliographic	Bibliográfica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.subfield.b	Fecha que aparece junto al título uniforme en la entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.subfield.a	Título uniforme	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.success.delete	Solicitud excluida con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.page_help	<p>La rutina de Proveedores permite el registro y búsqueda de Proveedores. La búsqueda tratará de encontrar cada uno de los términos digitados en los campos <em>Nombre Fantasía, Razón Social o CNPJ</em>.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.subfield.g	Información adicional	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.subfield.f	Fecha del trabajo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.530.subfield.a	Notas de disponibilidad de forma física	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.subfield.k	Subencabezamientos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.administration_maintenance	Manutención	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.requester	Solicitante	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.subfield.n	Número de la parte - sección de la obra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.subfield.l	Idioma del texto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.no_lendings	Este usuario no posee préstamos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.title.author	Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.field.id	N&ordm; del registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.111.subfield.a	Nombre del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.confirm_cancel_editing_title	Cancelar edición de registro de autoridad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.circulation_reservation_reserve	Realizar reservas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_699	Asunto lugar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.111.indicator.1	Forma de entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.access_control.card_available	Esta tarjeta está disponible	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.400.subfield.a	Apellido y/o Nombre del Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	label.login	Entrar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.title	Permisos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.button.import_this_page	Importar registros de esta página	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configurations.error.invalid_writable_path	Camino inválido. Este directorio no existe o el Biblivre no posee permiso de escritura.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.541.subfield.d	Fecha de adquisición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.541.subfield.e	Número atribuido a la adquisición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.541.subfield.b	Dirección	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.541.subfield.c	Forma de adquisición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.541.subfield.a	Nombre de la fuente	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.740.indicator.1.1	1 carácter a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.740.indicator.1.2	2 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.reindex.description.4	Problemas en la búsqueda, donde no se encuentran registros inscritos.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.740.indicator.1.0	Ningún carácter a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.541.subfield.f	Propietario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.541.subfield.h	Precio de compra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.740.indicator.1.9	9 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.740.indicator.1.7	7 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.740.indicator.1.8	8 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.541.subfield.o	Tipo de unidad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.740.indicator.1.5	5 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.111.subfield.k	Sub-encabezamientos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.reindex.description.2	Alteración en la configuración de campos aptos a ser buscados;	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.541.subfield.n	Cantidad de items adquiridos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.740.indicator.1.6	6 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
pt-BR	search.bibliographic.holdings_reserved	Reservas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
es	administration.accesscards.change_status.uncancel	La Tarjeta será recuperada y estará disponible para su uso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.reindex.description.3	Importación de registros de versiones antiguas del Biblivre; y	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.830	Entrada secundaria - Serie - Título Uniforme	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.740.indicator.1.3	3 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.740.indicator.1.4	4 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.fine.pending	Pendiente	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_080	CDU	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.reindex.description.1	La Reindización de la base de datos es el proceso en el cual el Biblivre analiza cada registro inscrito, creando índices en ciertos campos para que la búsqueda en ellos sea posible. Es un proceso demorado y que debe ser ejecutado solo en los casos específicos abajo:<br/>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.306.subfield.a	Tiempo de duración	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.active_lendings	Préstamos activos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.button.remove_login	Remover Login	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.subfield.a	Localización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.reservation.button.select_reader	Seleccionar lector	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.subfield.b	Sub-localización o colección	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.subfield.c	Localización en el estante	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configurations.error.save	No fue posible guardar las configuraciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.subfield.e	Código postal	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.label.example	ex.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.reservation.button.reserve	Reservar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.500.subfield.a	Notas generales	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.field.quantity	Cantidad de ejemplares	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.administration_z3950_servers	Servidores Z39.50	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.title.quantity	Cantidad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	login.error.same_password	La nueva contraseña debe ser diferente de la contraseña actual	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.usertype.confirm_cancel_editing.1	¿Usted desea cancelar la edición de este Tipo de Usuario?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.usertype.confirm_cancel_editing.2	Todas las alteraciones se perderán	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.field.code	Tarjeta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.user_type.success.save	Tipo de Usuario incluido con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.suffix	Sufijo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.400.subfield.a	Apellido y/o Nombre del autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.360.subfield.a	Término tópico adoptado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.late_lendings	Informe de Préstamos en Atraso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.subfield.z	Nota pública	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.856	Localización de obras por medio electrónico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.710.indicator.2.2	entrada analítica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.indexing_groups.other_name	Otras formas del nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.title.general.currency	Moneda	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.subfield.q	Condición física de la parte	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.subfield.x	Nota interna	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.field.delivered	Pedido recibido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.subfield.u	URI	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.group.acquisition	Adquisición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.field.supplier_select	Seleccione un Proveedor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.multi_schema_translations	Traducciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.subfield.j	Número de control en el estante	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.button.select_page	Seleccionar registros de esta página	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.on_the_field	En el campo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.subfield.n	Código del País	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.111.subfield.e	Nombre de subunidades del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.111.subfield.c	Lugar de realización del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.material_type	Tipo de material	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.111.subfield.d	Fecha de realización del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.fieldset.contact	Contactos/Teléfonos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.111.subfield.g	Informaciones adicionales	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.111.subfield.n	Número de orden del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	multi_schema.manage.error	Error	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.labels.selected_records_plural	{0} ejemplares seleccionados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_400	Otra forma de nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.common.button.upload	Enviar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.362	Información de Fechas de Publicación y/o Volumen	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.360	Remisiva VT (ver también) y TA (Término relacionado o asociado)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.field.supplier_select	Seleccione un Proveedor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.shelf_location	Localización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.700.indicator.2._	ninguna información suministrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.confirm_delete_record_question.inactive	¿Usted realmente desea marcar este usuario como "inactivo"?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.translations.upload.field.user_created	Cargar traducciones creadas por el usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.translations.error.dump	No fue posible generar el archivo de traducciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.error.couldnt_unzip_backup	No fue posible descompactar el backup seleccionado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.confirm_delete_record_title	Excluir registro de solicitud	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.error.invalid_database	Base de datos inexistente	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.created	Registrado en	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.page_help	<p>La rutina de Tarjetas de Acceso permite el registro y búsqueda de las Tarjetas utilizadas por la rutina de Control de Acceso. Para realizar el registro el Biblivre ofrece dos opciones:</p>\n<ul><li>Registrar Nueva Tarjeta: utilice para registrar solo una tarjeta de acceso;</li><li>Registrar Secuencia de Tarjetas: utilice para registrar más de una tarjeta de acceso, en secuencia. Utilize el campo "Previsualización" para verificar como serán las numeraciones de las tarjetas incluidas.</li></ul>\n<p>Al accesar a esa rutina, el Biblivre alistará automáticamente todos las Tarjetas de Acceso previamente registradas.  Usted podrá entonces filtrar esa lista, digitando el <em>Código</em> de una Tarjeta de Acceso que quiera encontrar.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.confirm_delete_record_question	¿Usted realmente desea excluir este registro de Pedido?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.administration_reports	Generar Informes	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.option.classification	Clasificación (CDD)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.field.url	URL	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.error.no_record_found	Ningún Registro válido encontrado en el archivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.database.record_count	Registros en esta base: <strong>{0}</strong>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.reservation.holdings.title	Buscar Registro Bibliográfico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.confirm_delete_record_title	Excluir registro de autoridad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.confirm_delete_record_question	¿Usted realmente desea excluir este registro bibliográfico?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	format.date_user_friendly	DD/MM/AAAA	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.title.holdings_creation_by_date	Informe del Total de Inclusiones de Obras por Período	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.birthday	Fecha de Nacimiento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.field.complement	Complemento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.750	Término tópico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.user_type	Tipo de Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.fine_popup.description	Esta devolución está atrasada y está sujeta al pago de multa. Verifique abajo las informaciones presentadas y confirme si la multa será agregada al registro del usuario para ser pagada en el futuro (Multar), si ella fue pagada en el momento de la devolución (Pagar) o si ella será abonada (Abonar).	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.340	Soporte físico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permission.success.permissions_saved	Permisos alterados con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.343	Datos de coordenada plana	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_013	Información del control de patentes	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.342	Datos de referencia geoespacial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.added_to_list	Agregado a la lista	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.marc_popup.description	Use la caja abajo para alterar el MARC de este registro antes de importarlo.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.710.indicator.1.2	nombre en el orden directo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.710.indicator.1.0	nombre invertido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.reindex.confirm	¿Desea confirmar la reindización de la base?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.710.indicator.1.1	nombre de la jurisdicción	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.090.subfield.b	Código del autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.090.subfield.a	Clasificación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.search_vocabulary	Vocabulario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.modified	Fecha Cancelamiento/Alteración	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.740	Entrada secundaria - Título Adicional - Analítico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_410	Otra forma de nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_411	Otra forma de nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.090.subfield.d	Número de ejemplar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.090.subfield.c	Edición / volumen	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.biblivre4restore.error	Error al restaurar backup	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_020	ISBN	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.indicator.2.9	9 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.indicator.2.8	8 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.indicator.2.7	7 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_024	ISRC	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.button.print_receipt	Imprimir recibo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_022	ISSN	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.indicator.2.2	2 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.indicator.2.1	1 carácter a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.indicator.2.0	Ningún caracter a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.indicator.2.6	6 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.indicator.2.5	5 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.indicator.2.4	4 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.form.remove	Remover	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.240.indicator.2.3	3 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.362.indicator.1	Formato de la fecha	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.acquisition_quotation_save	Guardar registro de cotización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.field.info	Observaciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.title.orders_by_date	Informe de Pedidos por Período	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.lend_success	Ejemplar prestado con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.holding_reservation	Reservas por serie del ejemplar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.button.edit	Editar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.confirm_cancel_editing.2	Todas las alteraciones se perderán	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.confirm_cancel_editing.1	¿Usted desea cancelar la edición de este registro de cotización?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.confirm_cancel_editing.1	¿Usted desea cancelar la inclusión de Tarjetas de Acceso?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.confirm_cancel_editing.2	Todas las alteraciones serán perdidas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.label_exclude_digital_media	Backup sin archivos digitales	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.administration_permissions	Logins y Autorizaciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.541.indicator.1	Privacidad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.circulation_list	Listar Usuarios	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.isrc_already_in_database	Ya existe un registro con este ISRC en la base de datos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.address_state	Estado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.button.save_as_new	Guardar como nuevo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.610.indicator.1	Forma de entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.subfield.z	Subdivisión geográfica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.indexing_groups.isrc	ISRC	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.select.default	Seleccione una opción	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.help_about_biblivre	Sobre el Biblivre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.subfield.x	Subdivisión general	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.subfield.y	Subdivisión cronológica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.save.success	Registros importados con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.confirm_cancel_editing_title	Cancelar edición de registro de proveedor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.upload_popup.uploading	Enviando archivo...	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	field.error.required	El rellenado de este campo es obligatorio	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.created	Fecha de registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.reservation.reserve_date	Fecha de reserva	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permission.success.create_login	Login y permisos creados con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	error.file_not_found	Archivo no encontrado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.indexing_groups.issn	ISSN	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.043.subfield.a	Código del área geográfica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.reservation.reservation_count	Registros reservados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.help_about_library	Sobre la Biblioteca	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.title.administration.z3950.server.active	Servidor z39.50 Lugar activo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.indexing_groups.entity	Entidad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.users.success.save	Usuario incluido con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.310.subfield.a	Periodicidad Corriente	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.holdings_reserved	Reservas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.310.subfield.b	Fecha de la periodicidad corriente	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.090	Número de llamada / Localización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.acquisition_request_delete	Excluir registro de requerimiento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.vocabulary.indexing_groups.vt_ta_term	Término Asociado (VT / TA)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.biblivre4restore.newest_backup	Backup más reciente	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.error.corrupted_backup_file	El backup seleccionado no es un archivo válido o está corrompido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.biblivre4restore.description_found_backups_1	Abajo están los backups encontrados en los documentos de su computadora. Para restaurar uno de estos backups, cliquee sobre su nombre.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.150	TE	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.circulation_lending_return	Realizar devoluciones de obras	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.users.failure.delete	Falla al excluir usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.confirm_cancel_editing_title	Cancelar edición de registro de solicitud	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.add_cards	Agregar Tarjetas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.description.general.pg_dump_path	Atención: Esta es una configuración avanzada, pero importante. El Biblivre intentará encontrar automáticamente el camino para el programa <strong>pg_dump</strong> y, excepto en casos donde sea exhibido un error abajo, usted no precisará alterar esta configuración. Esta configuración representa el camino, en el servidor donde el Biblivre está instalado, para lo ejecutable <strong>pg_dump</strong> que es distribuido junto al PostgreSQL. En caso que esta configuración estuviera inválida, el Biblivre no será capaz de generar copias de seguridad.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.cataloging_authorities_move	Mover registro de autoridad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.confirm_move_record_description_singular	¿Usted realmente desea mover este registro?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.change_status.title.cancel	Cancelar Tarjeta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.migration.groups.reservations	Reservas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.reindex.warning	Este proceso puede demorar algunos minutos, dependiendo de la configuración de hardware de su servidor. Durante este tiempo, el Biblivre no estará disponible para la búsqueda de registros, pero retornará cuando la indización termine.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.user.simple_term_title	Rellene los términos de la búsqueda	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.receipt.title	Título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.paid_value	Valor Total Pago	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.reservation.delete_failure	Falla al excluir la reserva	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.082.subfield.a	Número de Clasificación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.button.lend	Prestar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.acquisition	Adquisición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.913	Código Lugar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.vocabulary_150	Término Específico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.confirm_delete_record_question	¿Usted realmente desea excluir este registro de cotización?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.fieldset.database	Base de Datos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.clear_simple_search	Limpiar resultados de la búsqueda	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.source_search_subtitle	Seleccione una biblioteca remota y rellene los términos de la búsqueda. La búsqueda devolverá un límite de {0} registros. En caso que no encuentre el registro de interés, refine su búsqueda.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.vocabulary_550	Término Genérico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.phone_work_extension	Ramal del Teléfono Comercial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.confirm_delete_record_title.forever	Excluir usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.confirm_cancel_editing.1	¿Usted desea cancelar la edición de este registro bibliográfico?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.holding.confirm_cancel_editing_title	Cancelar edición de registro de ejemplar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.late_lendings_count	Total de Préstamos en Atraso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.confirm_cancel_editing.2	Todas las alteraciones se perderán	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.subfield.a	Título uniforme atribuido al documento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.no_records_found	Ningún registro encontrado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.subfield.d	Fecha que aparece junto al título uniforme de entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.field.receipt_date	Fecha de recepción	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.title.user	Informe por Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.subfield.p	Nombre de la parte - Sección de la obra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.number_of_holdings	Número de Ejemplares	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.database.main	Principal	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.subfield.f	Fecha de edición del ítem que está siendo procesado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.subfield.g	Informaciones adicionales	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.page_help	<p>La rutina de Solicitudes permite el registro y búsqueda de solicitudes de obras. Una solicitud es un registro de alguna obra que la Biblioteca desea adquirir, y puede ser utilizada para realizar Cotizaciones con los Proveedores previamente registrados.</p>\n<p>La búsqueda tratará de encontrar cada uno de los términos digitados en los campos <em>Solicitante, Autor o Título</em>.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.no_reserves	Este usuario no posee reservas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.subfield.l	Idioma del texto. Idioma del texto por extenso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730.subfield.k	Subencabezamientos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.translations.error.no_language_code_specified	El archivo de traducciones enviado no posee el identificador de idioma: <strong>*language_code</strong>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.082.subfield.2	Número de edición de la CDD	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.confirm_delete_record_question.forever	¿Usted realmente desea excluir este registro de cotización?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.210.indicator.1	Entrada secundaria de título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.210.indicator.2	Tipo de Título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.distributed.title	Título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permission.success.password_saved	Contraseña alterada con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_490	Serie	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.750.indicator.1.0	Ningún nivel especificado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.750.indicator.1.1	Asunto primario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.750.indicator.1.2	Asunto secundario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.z3950.confirm_delete_record.forever	El Servidor Z39.50 será excluido permanentemente del sistema y no podrá ser recuperado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_status.inactive	Inactivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.field.name	Razón Social	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.unavailable	Backup no disponible	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.digitalmedia_upload	Enviar medio digital	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.fine.success_pay_fine	Multa paga con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.circulation_lending	Préstamos y Devoluciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.holdings_count	Ejemplares	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.100.subfield.a	Apellido y/o nombre del autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.step_1_title	Seleccionar origen de los datos de la importación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.100.subfield.b	Numeración que sigue al nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.651.subfield.y	Subdivisión cronológica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.title.cataloging.accession_number_prefix	Prefijo del sello patrimonial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.651.subfield.x	Subdivisión general	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.reservation.record_list_reserved	Listar solo registros reservados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.651.subfield.z	Subdivisión geográfica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.indexing_groups.event	Evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.translations.error.javascript_locale_not_available	No existe un identificador de idioma javascript para el archivo de traducciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.321	Periodicidad Anterior	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.z3950.no_server_found	Ningún servidor z39.50 encontrado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	error.invalid_user	Usuario inválido o inexistente	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.user_late_lendings	Préstamos en Atraso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.migration.description	Seleccione abajo qué items desea importar de la base de datos del Biblivre 3	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.field.total_value	Valor total	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.field.supplier	Proveedor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.selected_records_singular	{0} registro seleccionado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.020.subfield.a	Número de ISBN	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.020.subfield.c	Modalidad de adquisición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.button.select_reader	Seleccionar lector	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.material_type.score	Partitura	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.indicator.2	Tipo de ordenación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.migration.groups.digital_media	Medios Digitales	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.address_number	Número	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.100.subfield.q	Forma completa del nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.error.no_quotation_found	Ninguna cotización encontrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.marc_field	Campo Marc	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.100.subfield.d	Fechas asociadas al nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.100.subfield.c	Título y otras palabras asociadas al nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.852.indicator.1	Esquema de clasificación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.field.delivery_time	Plazo de entrega (Prometido)	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.field.address	Dirección	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.authorities_100	Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.biblivre_report_header	Informes Biblivre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.option.all_digits	Todos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	field.error.digits_only	Este campo debe ser rellenado con números	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.300	Descripción física	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.change_password.repeat_password	Repita la nueva contraseña	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.306	Tiempo de duración	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.error.card_not_found	Ningúna Tarjeta encontrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.change_status.question.block	¿Desea realmente bloquear esta Tarjeta?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.z3950.confirm_delete_record_title.forever	Excluir Servidor Z39.50	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.change_status.title.block	Bloquear Tarjeta	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.button.select_user	Seleccionar Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.confirm_delete_record_title.forever	Excluir Tarjeta de Acceso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.342.indicator.1.0	Sistema de coordenada horizontal	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.651.subfield.a	Nombre geográfico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.change_status.unblock	La Tarjeta será desbloqueada y estará disponible para su uso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.change_status.block	La Tarjeta será bloqueada y estará indisponible para uso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.310	Periodicidad Corriente	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.342.indicator.1.1	Sistema de coordenada Vertical	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.circulation_access_control_list	Listar control de acceso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.user_type.success.delete	Tipo de Usuario excluido con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.database.title	Base de datos seleccionada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.cataloging_vocabulary_save	Guardar registro de vocabulario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.error.existing_cards	Las siguientes Tarjetas ya existen:	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.subfield.a	Título del trabajo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.title.holdings_by_date	Informe de Registro de Ejemplares	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.subfield.l	Idioma del texto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.342.indicator.2.0	Geográfico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.next	Próximo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.subfield.k	Subencabezamientos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.342.indicator.2.1	Proyección de mapa	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.field.quotation_select	Seleccione una Cotización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.342.indicator.2.2	Sistema de coordenadas en grid	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.342.indicator.2.3	Lugar planear	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
pt-BR	administration.setup.biblivre4restore.confirm_description	Você realmente deseja restaurar este Backup?	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	administration.setup.progress_popup.processing	O Biblivre desta biblioteca está em manutenção. Aguarde até que a mesma seja concluída.	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	administration.permissions.select.default	Selecione uma opção	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
es	marc.bibliographic.datafield.342.indicator.2.4	Lugar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.authorities_110	Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.subfield.g	Información adicional	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.342.indicator.2.5	Modelo geodésico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.lendings_current	Total de Libros en préstamo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.authorities_111	Autor Evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.342.indicator.2.6	Altitud	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.invalid_psql_path	Camino inválido. El Biblivre no será capaz de generar y restaurar backups ya que el archivo <strong>psql</strong> no fue encontrado.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.342.indicator.2.7	A especificar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
pt-BR	administration.setup.button.continue_to_biblivre	Ir para o Biblivre	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	administration.setup.biblivre4restore.title_found_backups	Backups Encontrados	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	administration.setup.biblivre4restore.success.description	Backup restaurado com sucesso	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	administration.setup.button.show_log	Exibir log	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	administration.maintenance.backup.error.psql_not_found	PSQL não encontrado	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	administration.setup.biblivre4restore.confirm_title	Restaurar Backup	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	error.biblivre_is_locked_please_wait	Este Biblivre está em manutenção. Por favor, tente novamente em alguns minutos.	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	administration.setup.biblivre4restore.button	Restaurar backup selecionado	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	administration.setup.biblivre4restore.success	Restauração de Backup	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	administration.setup.clean_install	Nova Biblioteca	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	administration.setup.biblivre4restore.field.upload_file	Selecionar arquivo de backup	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	administration.migration.migrate.error	Falha ao importar os dados	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	administration.setup.clean_install.button	Iniciar como uma nova biblioteca	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	administration.setup.biblivre4restore.error	Erro ao restaurar backup	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	administration.setup.biblivre4restore.newest_backup	Backup mais recente	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	administration.setup.biblivre4restore.description_found_backups_1	Abaixo estão os backups encontrados nos documentos do seu computador. Para restaurar um destes backups, clique sobre o seu nome.	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	administration.migration.migrate.success	Dados importados com sucesso	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	common.calculating	Calculando	2014-05-21 21:47:27.923	1	2014-05-21 21:47:27.923	1	f
pt-BR	text.main.noscript		2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	administration.maintenance.backup.description.4	O Backup somente de arquivos digitais é uma cópia de todos os arquivos de mídia digital que foram gravados no Biblivre, sem nenhum outro dado ou informação, como usuários, base catalográfica, etc.	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	circulation.custom.user_field.select.default	Selecione uma opção	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	administration.setup.biblivre4restore	Restaurar um Backup do Biblivre 4 ou Biblivre 5	2014-05-21 21:47:27.923	1	2022-12-04 11:05:55.562071	0	f
pt-BR	circulation.custom.user_field.id_cpf	CPF	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	administration.setup.upload_popup.processing	Processando...	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	multi_schema.manage.button.show_log	Exibir log	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	multi_schema.manage.error.create	Falha ao criar nova biblioteca.	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	cataloging.bibliographic.button.export_records	Exportar registros	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.custom.user_field.address_complement	Complemento	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	administration.permissions.items.cataloging_bibliographic_private_database_access	Acesso à Base Privada.	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	administration.setup.no_backups_found	Nenhum backup encontrado	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	administration.maintenance.backup.warning	Este processo pode demorar alguns minutos, dependendo da configuração de hardware do seu servidor.	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	circulation.custom.user_field.address	Endereço	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	circulation.custom.user_field.address_zip	CEP	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	circulation.custom.user_field.address_city	Cidade	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	administration.configuration.title.general.multi_schema	Habilitar Multi-bibliotecas	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	circulation.lending.reserved.warning	Todos os exemplares disponíveis deste registro estão reservados para outros leitores. O empréstimo pode ser efetuado, porém verifique as informações de reservas.	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	circulation.custom.user_field.phone_cel	Celular	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	administration.setup.upload_popup.uploading	Enviando arquivo...	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	circulation.custom.user_field.phone_home	Telefone Residencial	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	multi_schema.manage.error.description	Falha ao criar nova biblioteca	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	administration.permissions.groups.digitalmedia	Mídia Digital	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	administration.permissions.reader	Leitor	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	multi_schema.manage.success.create	Nova biblioteca criada com sucesso.	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	circulation.custom.user_field.birthday	Data de Nascimento	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	circulation.custom.user_field.address_state	Estado	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	multi_schema.manage.log_header	[Log de criação de nova biblioteca do BIBLIVRE 5]	2014-06-14 19:32:35.338749	1	2022-12-04 11:05:55.5474	1	f
pt-BR	circulation.custom.user_field.phone_work_extension	Ramal do Telefone Comercial	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	administration.permissions.items.digitalmedia_upload	Enviar mídia digital	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	circulation.custom.user_field.address_number	Número	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	circulation.custom.user_field.gender.1	Masculino	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	circulation.custom.user_field.gender.2	Feminino	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	circulation.custom.user_field.id_rg	Identidade	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	circulation.custom.user_field.phone_work	Telefone Comercial	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	administration.setup.upload_popup.title	Abrindo Arquivo	2014-06-14 19:32:35.338749	1	2014-06-14 19:32:35.338749	1	f
pt-BR	acquisition.supplier.confirm_delete_record_title.forever	Excluir registro de fornecedor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.circulation_user	Cadastro de Usuários	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.title.dewey	Relatório de Classificação Dewey	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.administration_reports	Relatórios	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.digits	Dígitos significativos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.material_type.object_3d	Objeto 3D	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.error.invalid_data	Não foi possível processar a operação. Por favor, tente novamente.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.button.cancel	Cancelar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.field.supplier	Fornecedor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.022.subfield.a	Número do ISSN	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.title.general.title	Nome da biblioteca	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.013.subfield.e	Estado da patente	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.013.subfield.d	Data	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.error.record_not_found	Registro não encontrado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.013.subfield.f	Parte de um documento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.confirm_cancel_editing.2	Todas as alterações serão perdidas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.confirm_cancel_editing.1	Você deseja cancelar a edição deste registro de Pedido?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.256.subfield.a	Características do arquivo de computador	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.date_from	De	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.date	Data	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.button_exclude_digital_media	Gerar backup sem arquivos digitais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.title.general.psql_path	Caminho para o programa psql	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.cataloging	Catalogação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.vocabulary_913	Código Local	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.013.subfield.a	Número	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.013.subfield.b	País	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.013.subfield.c	Tipo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.indicator.1.0	Nenhum caractere a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.indicator.1.1	1 caractere a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.indicator.1.2	2 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.upload_button	Enviar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.indicator.1.7	7 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.title.search.distributed_search_limit	Limite de resultados para buscas distribuídas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.default	Selecione...	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.indicator.1.8	8 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.490.indicator.1	Política de desdobramento de série	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.indicator.1.9	9 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.users_who_have_login_access	Listar apenas usuários que possuem login de acesso ao Biblivre	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.title.unit_value	Valor Unitário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.indicator.1.3	3 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.indicator.1.4	4 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.field.email	Email	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.indicator.1.5	5 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.indicator.1.6	6 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.circulation_user_cards	Impressão de Carteirinhas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.attachment.alias	Digite um nome para este arquivo digital	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.fieldset.title_info	Dados da Obra	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.611.indicator.1.2	sobrenome composto (obsoleto)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.611.indicator.1.3	nome de família	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.611.indicator.1.0	prenome simples ou composto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.611.indicator.1.1	sobrenome simples ou composto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.082	Classificação Decimal Dewey	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.080	Classificação Decimal Universal	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.555.indicator.1.8	Não gerar constante na exibição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.title_last_backups	Últimos Backups	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.marc_popup.title	Editar Registro MARC	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.access_control.arrival_time	Data de entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.record.success.update	Registro alterado com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.555.indicator.1.0	Índice remissivo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.fieldset.dewey	Classificação Dewey	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.title.requisition	Requisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.button.save	Salvar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.indicator.1.0	Não gera entrada para o título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.indicator.1.1	Gera entrada para o título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.button.save	Salvar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.095	Área do conhecimento do CNPq	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.administration_z3950_delete	Excluir registro de servidor z3950	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.fine_value	Valor da multa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.error.no_users_found	Nenhum usuário encontrado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.090	Número de chamada - Localização	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.confirm_delete_record_title	Excluir registro de cotação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.access_control.card_unavailable	Cartão indisponível	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.simple_term_title	Preencha o Código do Cartão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.error.invalid_restore_path	O diretório configurado para restauração dos arquivos de backup não é valido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.title.general.pg_dump_path	Caminho para o programa pg_dump	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.add_one_card	Cadastrar Novo Cartão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.administration_z3950_save	Salvar registro de servidor z3950	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.confirm_move_record_description_plural	Você realmente deseja mover estes {0} registros?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.labels.button.select_item	Selecionar exemplar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.isbn	ISBN	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.title.general.backup_path	Caminho de destino das cópias de segurança (Backups)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_300	Descrição física	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.confirm_cancel_editing.2	Todas as alterações serão perdidas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.translations.upload.button	Enviar o idioma	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.340.subfield.e	Suporte	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.confirm_cancel_editing.1	Você deseja cancelar a edição deste usuário?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.340.subfield.c	Materiais aplicados à superfície	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.340.subfield.d	Técnica em que se registra a informação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_306	Tempo de duração	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.340.subfield.a	Base e configuração do material	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.340.subfield.b	Dimensões	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.indicator.2._	nenhuma informação fornecida	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	error.invalid_method_call	Chamada a método inválido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.authorities_411	Outra forma do nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.authorities_410	Outra forma do nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.migration.groups.cataloging_bibliographic	Catálogo Bibliográfico e de Exemplares	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.distributed.issn	ISSN (incluindo hífens)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	error.no_permission	Você não tem permissão para executar esta ação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.button.new	Novo usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.confirm_delete_record.forever	Ele será excluído permanentemente do sistema e não poderá ser recuperado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.750.indicator.2	Tesauro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.750.indicator.1	Nível do assunto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.help_manual	Manual	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.field.id	N&ordm; do registro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.all_users	Relatório de Todos os Usuários	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.field.invoice_number	N&ordm; da Nota Fiscal	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.vocabulary.indexing_groups.te_term	Termo Específico (TE)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.610.subfield.x	Subdivisão geral	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.610.subfield.y	Subdivisão cronológico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.610.subfield.z	Subdivisão geográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.description_last_backups_1	Abaixo estão os links para download dos últimos backups realizados. É importante guardá-los em um local seguro, pois esta é a única forma de recuperar seus dados, caso necessário.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.450.subfield.a	Termo tópico não usado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.description_last_backups_2	Estes arquivos estão guardados no diretório especificado na configuração do Biblivre (<em>"Administração"</em>, <em>"Configurações"</em>, no menu superior). Caso este diretório não esteja disponível para escrita no momento do backup, um diretório temporário será usado em seu lugar. Por este motivo, alguns dos backups podem não estar disponíveis após certo tempo. <span class="attention">Recomendamos sempre fazer o download do backup e guardá-lo em um local seguro.</span>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.users.title	Pesquisar Leitor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.040.subfield.e	Fontes convencionais de descrições de dados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.700.indicator.1.3	nome de família	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.040.subfield.d	Agência que alterou o registro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.040.subfield.c	Agência que transcreveu o registro em formato legível por máquina	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.040.subfield.b	Idioma da catalogação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.040.subfield.a	Código da Agência Catalogadora	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.700.indicator.1.0	prenome simples ou composto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	error.invalid_json	O Biblivre não foi capaz de entender os dados recebidos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.700.indicator.1.1	sobrenome simples ou composto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	aquisition.request.error.request_not_found	Não foi possível encontrar a requisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.700.indicator.1.2	sobrenome composto (obsoleto)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.database	Base	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.success.block	Cartão bloqueado com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.z3950.error.delete	Falha ao excluir o servidor z39.50	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.610.subfield.c	Local de realização do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.description.search.results_per_page	Esta configuração representa a quantidade máxima de resultados que serão exibidas em uma única página nas pesquisas do sistema. Um número muito grande poderá deixar o sistema mais lento.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.610.subfield.d	Data da realização do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.610.subfield.a	Nome da entidade ou do lugar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.password	Senha	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.610.subfield.b	Unidades subordinadas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.user_name	Nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.button_digital_media_only	Gerar backup de arquivos digitais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.610.subfield.n	Número da parte - seção da obra - ordem do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.user_status.active	Ativo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.translations.error.save	Não foi possível salvar as traduções	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.610.subfield.l	Língua do texto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.610.subfield.k	Subcabeçalho. (emendas, protocolos, seleção, etc)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.610.subfield.g	Informações adicionais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.authorities_400	Outra forma do nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.610.subfield.t	Título da obra junto à entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.710.indicator.2	Tipo de entrada secundária	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.confirm_move_record_title	Mover registros	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.custom_count	Relatório de contagem do campo Marc	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.710.indicator.1	Forma de entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.user_signup	Data de Matrícula	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.550.subfield.z	Subdivisão geográfica adotada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.550.subfield.x	Subdivisão geral adotada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.550.subfield.y	Subdivisão cronológica adotada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.fieldset.dates	Período	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.362.subfield.z	Fonte de informação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.error.user_not_found	Usuário não encontrado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.migration.groups.users	Usuários, Logins de acesso e Tipos de Usuários	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	header.law	Lei de Incentivo à Cultura	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.110.indicator.1	Forma de entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.step_1_description	Neste passo, você pode importar um arquivo contendo registros nos formatos MARC, XML e ISO2709 ou fazer uma pesquisa em outras bibliotecas. Selecione abaixo o modo de importação desejado, selecionando o arquivo ou preenchendo os termos da pesquisa. No passo seguinte, você poderá selecionar quais registros deverão ser importados.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.vocabulary.confirm_delete_record_question	Você realmente deseja excluir este registro de vocabulário?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.printer_type.printer_24_columns	Impressora 24 colunas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.material_type.book	Livro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.database_count	Total de Registros nas Bases no Período	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.913.subfield.a	Código local	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.acquisition	Data de aquisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.source_file_subtitle	Selecione um arquivo contendo os registros a serem importados. O formato deste arquivo pode ser <strong>texto</strong>, <strong>XML</strong> ou <strong>ISO2709</strong>, desde que a catalogação original seja compatível com MARC.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.confirm_delete_record_question.forever	Você realmente deseja excluir este usuário?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.670	Origem das informações	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.title.general.default_language	Idioma padrão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.description.general.default_language	Esta configuração representa o idioma padrão para exibição do Biblivre.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.indicator.2	Número de caracteres a serem desprezados na alfabetação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.indicator.1	Gera entrada secundária na ficha	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.translations.error.java_locale_not_available	Não existe um identificador de idioma java para o arquivo de traduções	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.description.circulation.lending_receipt.printer.type	Esta configuração representa o tipo de impressora que será utilizada para a impressão de recibos de empréstimos.  Os valores possíveis são: impressora de 40 colunas, de 80 colunas, ou impressora comum (jato de tinta).	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.indicator.2.0	Parte do título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.685	Nota de histórico ou glossário (GLOSS)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.z3950.field.port	Porta	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.translations.upload.field.upload_file	Arquivo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.680	Nota de escopo (NE)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.indicator.2.5	Título adicional em página de rosto secundária	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.label.author_count	Quantidade de registros	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.indicator.2.6	Título de partida	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.indicator.2.7	Título corrente	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.indicator.2.8	Título da lombada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.indicator.2.1	Título paralelo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.indicator.2.2	Título específico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.loading	Carregando	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.indicator.2.3	Outro título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.indicator.2.4	Título da capa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.step_2_description	Neste passo, confira os registros que serão importados e importe-os individualmente ou em conjunto, através dos botões disponíveis no final da página. O Biblivre detecta automaticamente se o regristo é bibliográfico, autoridades ou vocabulário, porém permite que o usuário corrija antes da importação. <strong>Importante:</strong> Os registros importados serão adicionados à Base de Trabalho e deverão ser corrigidos e ajustados antes de serem movidos para a Base Principal. Isso evita que registros incorretos sejam adicionados diretamente à base de dados final.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.field.terms_of_payment	Forma de pagamento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_310	Peridiocidade	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.450	UP (remissiva para TE não usado)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.reservation.reserve_failure	Falha ao reservar a obra	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.550.subfield.a	Termo tópico adotado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.summary	Sumário do Catálogo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.option.dewey	Classificação Decimal Dewey	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.362.subfield.a	Informação de Datas de Publicação e/ou Volume	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.040	Fonte da Catalogação (NR)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.success.update	Fornecedor salvo com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.611.subfield.n	Número de ordem do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_362	Data da primeira publicação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	language_code	pt-BR	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.611.subfield.e	Nome das subunidades do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.611.subfield.c	Local de realização do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.611.subfield.a	Nome do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.change_password.current_password	Senha atual	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.830.subfield.v	Número do volume ou designação sequencial da série	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.reservation.error.select_reader_first	Para reservar um registro você precisa, primeiramente, selecionar um leitor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.indicator.1.0	Classificação da LC	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.indicator.1.2	National Library of Medicine Classification	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.indicator.1.1	CDD	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.indicator.1.4	Localização fixa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.indicator.1.3	Superintendent of Documents classification	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.indicator.1.6	Em parte separado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.indicator.1.5	Título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.operator.and_not	e não	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.indicator.1.7	Classificação específica	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.indicator.1.8	Outro esquema	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.material_type.periodic	Periódico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.830.subfield.a	Título Uniforme	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.edition	Edição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_field.name	Nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.title.all_users	Relatório Geral de Usuários	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.dewey	CDD	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.949.subfield.a	Tombo Patrimonial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.090.subfield.a	Classificação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.isbn_already_in_database	Já existe um registro com este ISBN na base de dados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.090.subfield.b	Código do autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.record.success.delete	Registro excluído com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.090.subfield.c	Edição - volume	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.090.subfield.d	Número do Exemplar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.vocabulary_040	Fonte de catalogação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.555.indicator.1._	Índice	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.holdings_lent	Emprestados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.description.search.result_limit	Esta configuração representa a quantidade máxima de resultados que serão encontrados em uma pesquisa catalográfica. Este limite é importante para evitar lentidões no Biblivre em bibliotecas que possuam uma grande quantidade de registros. Caso a quantidade de resultados da pesquisa do usuário exceda este limite, será recomendado que ele melhore os filtros da pesquisa.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.record_imported_successfully	Registro importado com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.buttons.dismiss_fine	Abonar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.returned_lendings	Empréstimos devolvidos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.257.subfield.a	País da entidade produtora	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.back_to_search	Retornar à pesquisa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	error.invalid_database		2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.vocabulary_450	Termo Use Para	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.button.edit_marc	Editar MARC	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.wait	Aguarde	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.z3950.success.save	Servidor z39.50 salvo com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.611.subfield.y	Subdivisão cronológico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.611.subfield.x	Subdivisão geral	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.indicator.1._	Nenhuma informação fornecida	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.611.subfield.z	Subdivisão geográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630	Assunto - Título uniforme	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.material_type.music	Música	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.z3950.success.delete	Servidor z39.50 excluído com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.611.subfield.t	Título da obra junto à entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.field.status	Situação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.611.subfield.d	Data da realização do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.670.subfield.b	Informações encontradas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.fine_popup.title	Devolução em atraso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.670.subfield.a	Nome retirado de	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.receipt.lending_date	Data de Empréstimo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.buttons.pay_fine	Pagar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.410.subfield.a	Nome da entidade ou do lugar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.migration.groups.cataloging_vocabulary	Catálogo de Vocabulário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.e	Localização	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.b	Descrição da coleção impressa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.c	Tipo de aquisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.page_help	<p>A rotina de Permissões permite a criação de Login e Senha para um usuário, assim como a definição de suas permissões de acesso ou utilização das diversas rotinas do Biblivre.</p>\n<p>A pesquisa buscará os usuários já cadastrados no Biblivre, e funciona da mesma forma que a pesquisa simplificada da rotina de Cadastro de Usuários.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.confirm_delete_record.trash	Ele será movido para a base de dados "lixeira"	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.indexing_groups.all	Qualquer campo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.651	Assunto - Nome geográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.650	Assunto - Tópico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.confirm_delete_record.forever	O Cartão será excluído permanentemente do sistema e não poderá ser recuperado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.help_faq	Perguntas Frequentes	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.distributed.subject	Assunto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.success.save	Cartão incluído com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_852	Notas públicas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.acquisition_order	Pedidos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.translations.error.load	Não foi possível ler o arquivo de traduções	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.translations.upload_popup.title	Enviando Arquivo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.id	Nro. Registro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.error.no_request_found	Não foi possível encontrar nenhuma Requisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.confirm_delete_record.forever	Ele será excluído permanentemente do sistema e não poderá ser recuperado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.cataloging_bibliographic_save	Salvar registro bibliográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.original_value	Valor original	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.material_type.photo	Foto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.acquisition_supplier_delete	Excluir registro de fornecedor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.z3950.confirm_delete_record_question.forever	Você realmente deseja excluir este Servidor Z39.50?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.confirm_delete_record.trash	Ele será movido para a base de dados "lixeira"	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.z	Nota padrão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.q	Descrição do índice em multimeio	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.p	Descrição da coleção em multimeio	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.o	Descrição do índice em microfilme	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_830	Título uniforme	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.n	Descrição da coleção em microfilme	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.u	Descrição do índice em outros suportes	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.t	Descrição da coleção em outros suportes	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.material_type.pamphlet	Panfleto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.s	Descrição do índice em braile	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.r	Descrição da coleção em braile	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.i	Descrição do índice com acesso on-line	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.f	Código da biblioteca no CCN	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.g	Descrição do índice de coleção impressa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.l	Descrição da coleção em microficha	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.m	Descrição do índice em microficha	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.j	Descrição da coleção em CD-ROM	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.750.indicator.2	Tesauro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.k	Descrição do índice em CD-ROM	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.issn	ISSN	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.750.indicator.1	Nível do assunto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.610	Assunto - Entidade Coletiva	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.search_authorities	Autoridades	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.a	Sigla da biblioteca	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.indicator.2.2	2 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.description.general.psql_path	Atenção: Esta é uma configuração avançada, porém importante. O Biblivre tentará encontrar automaticamente o caminho para o programa <strong>psql</strong> e, exceto em casos onde seja exibido um erro abaixo, você não precisará alterar esta configuração. Esta configuração representa o caminho, no servidor onde o Biblivre está instalado, para o executável <strong>psql</strong> que é distribuído junto do PostgreSQL. Caso esta configuração estiver inválida, o Biblivre não será capaz de gerar e restaurar cópias de segurança.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.611	Assunto - Evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947.subfield.d	Ano da última aquisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.access_control.card_in_use	Cartão em uso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.fieldset.field_count	Contagem por campo Marc	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.041.subfield.b	Código do idioma do sumário ou resumo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.041.subfield.a	Código do idioma do texto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.holding.confirm_delete_record_question	Você realmente deseja excluir este registro de exemplar?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.reindex.button_bibliographic	Reindexar base bibliográfica	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.option.database.main	Principal	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.600	Assunto - Nome pessoal	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.045.indicator.1.0	Data - período únicos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.041.subfield.h	Código do idioma do documento original	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.field.status	Situação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.045.indicator.1.2	Extensão de datas - períodos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.045.indicator.1.1	Data - período múltiplos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.indexing_groups.subject	Assunto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.confirm_delete_record.inactive	Ele sairá da lista de pesquisas e só poderá ser encontrado através da "pesquisa avançada", de onde poderá ser excluído permanentemente ou recuperado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.150.subfield.z	Subdivisão geográfica adotada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.place	Local	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.150.subfield.y	Subdivisão cronológica adotada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.150.subfield.x	Subdivisão geral adotada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.isrc	ISRC	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.migration.groups.lendings	Empréstimos ativos, histórico de empréstimos e multas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.150.subfield.a	Termo tópico adotado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.342.subfield.d	Escala da Longitude	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.342.subfield.c	Escala da Latitude	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.user_type.error.save	Falha ao salvar o Tipo de Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.migration.groups.acquisition	Aquisições (Fornecedor, Requisição, Cotação e Pedido)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.database.trash_full	Lixeira	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.reservation.users.title	Pesquisar Leitor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.status.any	Qualquer	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.confirm_delete_record_question.forever	Você realmente deseja excluir este Cartão?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	field.error.invalid	Este valor não é válido para este campo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.150.subfield.i	Qualificador	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.342.subfield.a	Nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.342.subfield.b	Unidade das Coordenadas ou Unidade da Distância	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.administration_usertype_save	Salvar registro de tipo de usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.access.user.search	Usuários	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.vocabulary.indexing_groups.all	Qualquer campo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_876	Nota de acesso restrito	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.100.indicator.1.3	nome de família	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.change_status.question.unblock	Deseja realmente desbloquear este Cartão?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.100.indicator.1.1	sobrenome simples ou composto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.material_type.movie	Filme	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.migration.groups.cataloging_authorities	Catálogo de Autoridades	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.100.indicator.1.2	sobrenome composto (obsoleto)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.100.indicator.1.0	prenome simples ou composto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.holdings	Relatório de Cadastro de Exemplares	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.indicator.2.3	3 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.field.unit_value	Valor Unitário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.indicator.2.1	1 caractere a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.711.indicator.1	Forma de entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.indicator.2.0	Nenhum caractere a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.indicator.2.7	7 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.indicator.2.6	6 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.indicator.2.5	5 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.indicator.2.4	4 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.administration_usertype_delete	Excluir registro de tipo de usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.indicator.2.9	9 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.indicator.2.8	8 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.status.in_use	Em uso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.save_as_new	Salvar como Novo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	error.void		2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.author	Autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.670	Origem das informações	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.field.info	Observações	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.author	Autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.status.cancelled	Cancelado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.error.invalid_backup_type	O modo de backup selecionado não existe	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.operator.or	ou	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.110	Autor - Entidade coletiva	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.111	Autor - Evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.subfield.b	Complemento do título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.fieldset.author	Pesquisa por Autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.user_type.field.lending_limit	Limite de empréstimos simultâneos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	label.username	Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.subfield.a	Título/título abreviado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.error.delete.user_has_lendings	Este usuário possui empréstimos ativos.  Realize a devolução antes de excluir este usuário.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.access_control.user_has_card	Usuário já possui um cartão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.subfield.g	Miscelânea	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.accesscards.select_card	Selecionar Cartão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.subfield.f	Informação de volume/número de fascículo e/ou data da obra	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.subfield.i	Exibir texto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.subfield.h	Meio físico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.504.subfield.a	Notas de bibliografia	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.receipt.expected_return_date	Data para devolução	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.z3950.field.name	Nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.subfield.n	Número da parte/seção da obra	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.invalid_backup_path	Caminho inválido. Este diretório não existe ou o Biblivre não possui permissão de escrita.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.vocabulary.confirm_delete_record.trash	Ele será movido para a base de dados "lixeira"	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.subfield.p	Nome da parte/seção da obra	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.100	Autor - Nome pessoal	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.new_value	Novo valor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.access_control.page_help	<p>O <strong>"Controle de Acesso"</strong> permite gerenciar a entrada e permanência dos leitores nas instalações da biblioteca. Selecione o leitor através de uma pesquisa por nome ou matrícula e digite o número de um cartão de acesso disponível para vincular aquele cartão ao leitor.</p>\n<p>No momento da saída do leitor, você poderá desvincular o cartão procurando pelo código do mesmo</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.700.indicator.2.2	entrada analítica	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.field.title	Título Principal	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.distributed.author	Autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.indexing_groups.total	Total	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.marc_field	Valor do campo Marc	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.indicator.2	Número de caracteres a serem desprezados na alfabetação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.indicator.1	Gera entrada secundária na ficha	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.material_type.computer_legible	Arquivo de Computador	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.usertype.confirm_delete_record.forever	O Tipo de Usuário será excluído permanentemente do sistema e não poderá ser recuperado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.translations.upload.title	Enviar arquivo de idioma	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.administration_datamigration	Importar dados do Biblivre 3	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130	Obra anônima	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.error.save	Falha ao salvar o Cartão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.subfield.f	Data da edição do item que está sendo processado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.distributed.page_help	<p>A pesquisa distribuída permite recuperar informações sobre registros em acervos de outras bibliotecas, que disponibilizam seus registros para pesquisa e catalogação colaborativa.</p>\n<p>Para realizar uma pesquisa, preencha os termos da pesquisa, selecionando o campo de interesse. Em seguida, selecione uma ou mais bibliotecas onde os registros deverão ser localizados. <span class="warn">Atenção: selecione poucas bibliotecas para evitar que a busca distribuída fique muito lenta, visto que ela depende da comunicação entre as bibliotecas e o tamanho de cada acervo.</span></p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.printer_type.printer_common	Impressora comum	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.number_of_titles	Número de Títulos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.user_count_by_type	Totais por Tipos de Usuários	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.login_data	Dados para acesso ao sistema	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.employee	Funcionário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.step_2_title	Selecionar registros para importação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.uncancel	Recuperar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.current_value	Valor atual	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.record.error.delete	Falha ao exluir o Registro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.confirm_cancel_editing_title	Cancelar edição de registro de Pedido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permission.error.delete	Falha ao excluir o login	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.user_status.blocked	Bloqueado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.start_date	Data Inicial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.680.subfield.a	Nota de escopo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.button.return	Devolver	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.095.subfield.a	Área do conhecimento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.confirm_cancel_editing_title	Cancelar edição de usuáro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.vocabulary.confirm_cancel_editing.2	Todas as alterações serão perdidas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.vocabulary.confirm_cancel_editing.1	Você deseja cancelar a edição deste registro de vocabulário?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.import_as	Importar como:	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.cataloging_authorities_save	Salvar registro de autoridade	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.confirm_delete_record.forever	Ele será excluído permanentemente do sistema e não poderá ser recuperado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.material_type.thesis	Tese	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.import_popup.importing	Importando registros, por favor, aguarde	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.fieldset.title.values	Valores	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.150	TE	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.acquisition_request	Requisições	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.750.indicator.1.0	Nenhum nível especificado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.750.indicator.1.1	Assunto primário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.750.indicator.1.2	Assunto secundário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.translations.download.description	Selecione abaixo o idioma que deseja baixar.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.field.zip_code	CEP	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.button.delete	Excluir	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.migration.groups.z3950_servers	Servidores Z39.50	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.lending_date	Data do empréstimo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.field.info	Observações	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.field.trademark	Nome Fantasia	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.remove_item_button	Excluir	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.045.indicator.1._	Subcampos |b ou |c não estão presentes	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	aquisition.supplier.error.supplier_not_found	Não foi possível encontrar o fornecedor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.other_name	Outra Forma do nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_cards.button.print_user_cards	Imprimir carteirinhas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.vocabulary.indexing_groups.tg_term	Termo Geral (TG)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.change_password.description.6	Caso o usuário perca a sua senha, o mesmo deverá entrar em contato com o Administrador ou Bibliotecário responsável pelo Biblivre, que poderá fornecer uma nova senha.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.issn_already_in_database	Já existe um registro com este ISSN na base de dados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.subfield.a	Título uniforme atribuído ao documento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.z3950.field.url	URL	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.error.delete	Falha ao exluir o Cartão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.550.subfield.y	Subdivisão cronológica adotada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.subfield.d	Data que aparece junto ao título uniforme na entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.550.subfield.z	Subdivisão geográfica adotada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.subfield.l	Língua do texto. Idioma do texto por extenso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.subfield.k	Subcabeçalhos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.receipt.author	Autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.subfield.g	Informações adicionais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.913.subfield.a	Código local	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.receipt.return_date	Data de devolução	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.change_password.description.1	A troca de senha é o processo no qual um usuário pode alterar a sua senha atual por uma nova. Por questões de segurança, sugerimos que o usuário realize este procedimento periodicamente.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.record.error.move	Falha ao mover os Registros	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.administration_datamigration	Migração de Dados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.button.search	Pesquisar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.change_password.description.3	Misture letras, símbolos especiais e números na sua senha	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.change_password.description.2	A única regra para criação de senhas no Biblivre é a quantidade mínima de 3 caracteres. No entanto, sugerimos seguir as seguintes diretivas:	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.page_help	<p>A importação de registros permite expandir sua base de dados sem que haja necessidade de catalogação manual. Novos registros podem ser importados através de pesquisas Z39.50 ou a partir de arquivos exportados por outros sistemas de biblioteconomia.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.change_password.description.5	Use uma quantidade de caracteres superior ao recomendado.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.subfield.p	Nome da parte - seção da obra	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.change_password.description.4	Use letras maiúsculas e minúsculas; e	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.550.subfield.a	Termo tópico adotado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.subfield.y	Subdivisão cronológico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.subfield.z	Subdivisão geográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.subfield.x	Subdivisão geral	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.750.subfield.z	Subdivisão geográfica	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.750.subfield.y	Subdivisão cronológica	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.block	Bloquear	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.750.subfield.x	Subdivisão geral	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.949.subfield.a	Tombo patrimonial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.750.subfield.a	Termo tópico adotado no tesauro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.410.subfield.a	Nome da entidade ou do lugar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.550.subfield.x	Subdivisão geral adotada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.renew_success	Empréstimo renovado com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.cataloging_vocabulary	Vocabulário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.labels.never_printed	Listar apenas exemplares que nunca tiveram etiquetas impressas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.user_total_lending_list	Histórico de empréstimos a este leitor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.material_type.manuscript	Manuscrito	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.step	Passo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.operator.and	e	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.cataloging_authorities_delete	Excluir registro de autoridade	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.change_status.question.cancel	Deseja realmente cancelar este Cartão?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.button.cancel	Cancelar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.success.generate	Relatório gerado com sucesso. O mesmo será aberto em outra página.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.labels.selected_records_singular	{0} exemplar selecionado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.502.subfield.a	Notas de dissertação ou tese	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.groups.acquisition	Aquisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.auto_download	Backup realizado, baixando automaticamente em alguns segundos...	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.database.record_deleted	Registro excluído definitivamente	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.040.subfield.c	Agência que transcreveu o registro em formato legível por máquina	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.040.subfield.b	Língua da catalogação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.040.subfield.e	Fontes convencionais de descrições de dados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.040.subfield.d	Agência que alterou o registro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.040.subfield.a	Código da agência catalogadora	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.title.searches_by_date	Relatório de Total de Pesquisas por Período	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	error.runtime_error	Erro inesperado durante a execução da tarefa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.field.subtitle	Títulos paralelos/subtítulo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.045.indicator.1	Tipo do período cronológico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.success.save	Fornecedor incluído com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.administration_backup	Realizar cópia de segurança da base de dados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.form.hidden_subfields_plural	Exibir {0} subcampos ocultos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.indicator.1.3	Não gerar nota, gerar entrada secundária de título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.reservation.page_help	<p>Para realizar uma reserva você deverá selecionar o leitor para o qual a reserva será realizada e, em seguida, selecionar o registro que será reservado. A pesquisa pelo leitor pode ser feita por nome, matrícula ou outro campo previamente cadastrado. Para encontrar o registro, realize uma pesquisa similar à pesquisa bibliográfica.</p>\n<p>Cancelamentos podem ser feitos selecionando o leitor que possui a reserva.</p><p>A duração da reserva é calculada de acordo com o tipo de usuário, configurado pelo menu <strong>Administração</strong> e definido durante o cadastro do leitor.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.users_with_pending_fines	Listar apenas usuários com multas pendentes	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.confirm_delete_record_title	Excluir registro de fornecedor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.acquisition	Relatório de Pedidos de Aquisição Efetuados Por Período	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.confirm_delete_record.forever	Tanto o Login do Usuário quanto suas Permissões serão excluídos permanentemente do sistema e não poderão ser recuperados.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.return_success	Exemplar devolvido com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.search_count	{current} / {total}	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.printer_type.printer_80_columns	Impressora 80 colunas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.description.administration.z3950.server.active	Esta configuração representa se o servidor z39.50 local estará ativo. Nos casos de instalações multi-biblioteca, o nome da Coleção do servidor z39.50 será igual ao nome de cada biblioteca. Por exemplo, o nome da coleção para esta instalação é "{0}".	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.search_z3950	Distribuída	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.400	Outra forma do nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.user.name_or_id	Nome ou Matrícula	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.error.start_less_than_or_equals_end	O Número inicial deve ser menor ou igual ao Número final	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.users.success.update	Usuário salvo com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.title	Cópia de Segurança (Backup)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.user.field	Campo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.error.invalid_marc	Falha ao ler o Registro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.vocabulary.confirm_cancel_editing_title	Cancelar edição de registro de vocabulário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.no_fines	Este usuário não possui multas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.410	Outra forma do nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.button.generate_report	Emitir Relatório	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.110.subfield.d	Data da realização do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.110.subfield.c	Local de realização do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.110.subfield.b	Unidades subordinadas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.accession_number	Tombo Patrimonial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.holding.confirm_cancel_editing.2	Todas as alterações serão perdidas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.holding.confirm_cancel_editing.1	Você deseja cancelar a edição deste registro de exemplar?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.accesscards.return.success	Cartão devolvido com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.110.subfield.l	Língua do texto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.title	Importação de Registros	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.in_this_library	Nesta biblioteca	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.110.subfield.n	Número da parte seção da obra ordem do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.holding.confirm_delete_record.trash	Ele será movido para a base de dados "lixeira"	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.usertype.confirm_delete_record_question.forever	Você realmente deseja excluir este Tipo de Usuário?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.users.success.delete	Usuário excluído permanentemente	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	label.logout	Sair	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.field.quotation	Cotação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.field.requisition_select	Selecione uma Requisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.title.holdings	Relatório de Tombo Patrimonial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	warning.create_backup	Você está a mais de 3 dias sem gerar uma cópia de segurança (backup)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.user.remove_item_button	Excluir	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.110.subfield.a	Nome da entidade ou do lugar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.580	Nota de Ligação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.user_status	Situação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_status.active	Ativo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.indicator.1.1	Gerar nota e entrada secundária de título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.740.subfield.a	Título adicional - Título analítico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.indicator.1.0	Gerar nota, não gerar entrada secundária de título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.database_work	Trabalho	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.usertype.confirm_delete_record_title.forever	Excluir Tipo de Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.acquisition_quotation_delete	Excluir registro de cotação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.switch_to	Trocar para	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.indicator.1.2	Não gerar nota nem entrada secundária de título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.common.digital_files	Arquivos Digitais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.dewey	Estatística por Classificação Dewey	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.740.subfield.n	Número da parte - Seção da obra	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.740.subfield.p	Nome da parte - Seção da obra	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.field.country	País	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.labels.page_help	<p>O módulo <strong>"Impressão de Etiquetas"</strong> permite gerar as etiquetas de identificação interna e de lombada para os exemplares da biblioteca.</p>\n<p>É possível gerar as etiquetas de um ou mais exemplares em uma única impressão, utilizando a pesquisa abaixo. Fique atento ao detalhe de que o resultado desta pesquisa é uma lista de exemplares e não de registros bibliográficos.</p>\n<p>Após encontrar o(s) exemplare(s) de interesse, use o botão <strong>"Selecionar exemplar"</strong> para adicioná-los à lista de impressão de etiquetas. Você poderá fazer diversas pesquisas, sem perder a seleção feita anteriormente. Quando finalmente estiver satisfeito com a seleção, clique no botão <strong>"Imprimir etiquetas"</strong>. Será possível selecionar qual modelo da folha de etiquetas a ser usado e de qual posição iniciar.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.024.indicator.1.2	International Standard Music Number (ISMN)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.confirm_delete_record.trash	Ele será movido para a base de dados "lixeira"	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.024.indicator.1.0	International Standard Recording Code (ISRC)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.receipt.accession_number	Tombo Patrimonial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.access_control.user_has_no_card	Não há cartão associado a este usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.date_to	a	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.deleted	Excluído	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.in_these_libraries	Nestas bibliotecas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.field.author	Autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.cataloging_import	Importação de Registros	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.590	Notas locais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.yes	Sim	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.595	Notas para inclusão em bibliografias	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.translations.download.title	Baixar arquivo de idioma	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.button.import_this_record	Importar este registro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.status.in_use_and_blocked	Em uso e bloqueado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.lendings_late	Total de Livros atrasados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.confirm_delete_record_question	Você realmente deseja excluir este registro de fornecedor?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.button.select_item	Selecionar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.450.subfield.a	Termo tópico não usado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.users.error.save	Falha ao gravar o Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.342.indicator.2	Dimensões de referência geospacial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.580.subfield.a	Nota de Ligação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.342.indicator.1	Dimensões de referência geospacial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.user_returned_lendings	Histórico de Devoluções	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.administration_z3950_search	Listar servidores z3950	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	login.password.success	Senha alterada com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.830.indicator.2.9	9 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.830.indicator.2.8	8 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	label.password	Senha	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_cards.button.select_item	Selecionar usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.confirm_delete_record.forever	Ele será excluído permanentemente do sistema e não poderá ser recuperado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.select_marc_field	Selecione um campo Marc	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.simple_search	Pesquisa Bibliográfica Simplificada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.receipt.holding_id	Nro. Registro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.form.repeat	Repetir	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.830.indicator.2.2	2 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.830.indicator.2.3	3 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.830.indicator.2.0	Nenhum caractere a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.830.indicator.2.1	1 caractere a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.confirm_cancel_editing_title	Cancelar edição de registro bibliográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.830.indicator.2.6	6 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246	Forma Variante de Título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.830.indicator.2.7	7 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.830.indicator.2.4	4 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.830.indicator.2.5	5 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.750.subfield.a	Termo tópico adotado no tesauro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.title.topographic	Relatório Topográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.user_status.pending_issues	Possui pendências	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.receipt.returns	Devoluções	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.error.no_records_found	Nenhum registro encontrado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.today	Hoje	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.111.indicator.1.0	nome invertido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.lendings	Relatório de Empréstimos por Período	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.vocabulary_360	Termo Associado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	error.form_invalid_values	Foram encontrados erros no preenchimento do formulário abaixo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.user	Relatório por Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	field.error.max_length	Este campo deve possuir no máximo {0} caracteres	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.110.indicator.1	Forma de entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.555	Nota de Índice Cumulativo ou Remissivo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.isbn	ISBN	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.status.blocked	Bloqueado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.inactive_users_only	Listar apenas usuários inativos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configurations.page_help	<p>A rotina de Configurações permite a configuração de diversos parâmetros utilizados pelo Biblivre, como por exemplo o Título da Biblioteca, o Idioma Padrão ou a Moeda a ser utilizada. Cada configuração possui um texto explicativo para facilitar a sua utilização.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.title.lendings_by_date	Relatório de Empréstimos por Período	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.last_backup	Último Backup	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.edit	Editar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.550	TG (termo genérico)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_243	Título uniforme coletivo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.delete	Excluir	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.indicator.2.2	Numeração alternada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.360	Remissiva VT (ver também) e TA (termo relacionado ou associado)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	warning.change_password	Você ainda não mudou a senha padrão de administrador	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.total	Total	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_240	Título uniforme	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.indicator.2.1	Numeração primária	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.indicator.2.0	Não numerada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.525	Nota de Suplemento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.button.print_return_receipt	Imprimir recibo de devolução	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_cards.popup.description	Selecione em qual etiqueta deseja iniciar a impressão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.error.delete	Falha ao exluir a Requisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.521	Notas de público alvo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.024.indicator.1	Tipo do número ou código normalizado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.administration_accesscards_list	Listar cartões de acesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_245	Título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.520	Notas de resumo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.250.subfield.b	Informações adicionais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.250.subfield.a	Indicação da edição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.user_type.error.type_has_users	Este Tipo de Usuário possui Usuários cadastrados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.user_type.error.delete	Falha ao exluir o Tipo de Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.210.indicator.2._	Título chave abreviado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.add_multiple_cards	Cadastrar Sequência de Cartões	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	digitalmedia.error.file_not_found	O arquivo especificado não foi encontrado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.error.delete	Falha ao exluir a cotação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	warning.fix_now	Resolver este problema	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.holding.availability.available	Disponível	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.confirm_delete_record_title	Excluir registro bibliográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.status.available	Disponível	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.holding.availability	Disponibilidade	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.subfield.c	Indicação de responsabilidade da obra	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.return_date	Data da devolução	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.subfield.a	Título principal	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.subfield.b	Títulos paralelos/subtítulos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.cataloging_vocabulary_move	Mover registro de vocabulário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.page_help	<p>A pesquisa bibliográfica permite recuperar informações sobre os registros do acervo desta biblioteca, listando seus exemplares, campos catalográficos e arquivos digitais.</p>\n<p>A forma mais simples é usar a <strong>pesquisa simplificada</strong>, que buscará cada um dos termos digitados nos seguintes campos: <em>{0}</em>.</p>\n<p>As palavras são pesquisadas em sua forma completa, porém é possível usar o caractere asterisco (*) para buscar por palavras incompletas, de modo que a pesquisa <em>'brasil*'</em> encontre registros que contenham <em>'brasil'</em>, <em>'brasilia'</em> e <em>'brasileiro'</em>, por exemplo. Aspas duplas podem ser usadas para encontrar duas palavras em sequência, de modo que a pesquisa <em>"meu amor"</em> encontre registros que contenham as duas palavras juntas, mas não encontre registros com o texto <em>'meu primeiro amor'</em>.</p>\n<p>A <strong>pesquisa avançada</strong> confere um maior controle sobre os registros localizados, permitindo, por exemplo, buscar por data de catalogação ou exatamente no campo desejado.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.error.invalid_photo_extension	A extensão do arquivo selecionado não é válida para a foto do usuário. Use arquivos .png, .jpg, .jpeg ou .gif	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.541.indicator.1._	nenhuma informação fornecida	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.database.private_full	Base Privativa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.534	Notas de fac-símile	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.creation_date	Data Inclusão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.530	Notas de disponibilidade de forma física	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.750	Termo tópico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.indicator.2._	Nenhuma informação fornecida	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.vocabulary.page_help	<p>A pesquisa de vocabulário permite recuperar informações sobre os termos presentes no acervo desta biblioteca, caso catalogados.</p>\n<p>A pesquisa buscará cada um dos termos digitados nos seguintes campos: <em>{0}</em>.</p>\n<p>As palavras são pesquisadas em sua forma completa, porém é possível usar o caractere asterisco (*) para buscar por palavras incompletas, de modo que a pesquisa <em>'brasil*'</em> encontre registros que contenham <em>'brasil'</em>, <em>'brasilia'</em> e <em>'brasileiro'</em>, por exemplo. Aspas duplas podem ser usadas para encontrar duas palavras em sequência, de modo que a pesquisa <em>"meu amor"</em> encontre registros que contenham as duas palavras juntas, mas não encontre registros com o texto <em>'meu primeiro amor'</em>.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.show_all	Mostrar todos os {0} backups	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.field.response_date	Data de Chegada da Cotação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.title.bibliography	Relatório de Bibliografia por Autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_260	Imprenta	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.cataloging_bibliographic_delete	Excluir registro bibliográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.simple_search	Pesquisa Simplificada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.500	Notas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permission.success.delete	Login excluído com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.501	Notas iniciadas com a palavra "com"	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.502	Notas de dissertação ou tese	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.504	Notas de bibliografia	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.505	Notas de conteúdo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.541.indicator.1.1	não confidencial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.administration_password	Troca de Senha	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.541.indicator.1.0	confidencial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lendings.holding_list_lendings	Listar apenas exemplares emprestados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.buttons.apply_fine	Multar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_250	Edição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.datafield	Campo MARC	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_255	Escala	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_256	Características do arquivo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_257	Local de produção	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_258	Informação sobre o material	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.success.update	Cotação salva com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.location	Localização	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_field.photo	Foto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	login.error.empty_login	O campo login não pode ser vazio	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.515	Nota de Peculiaridade na Numeração	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.selected_records_plural	{0} registros selecionados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.clear_search	Limpar termos da pesquisa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.biblio	Bibliográficos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.backup_not_complete	Backup não finalizado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.error.no_supplier_found	Não foi possível encontrar nenhum fornecedor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.confirm_cancel_editing_title	Cancelar edição de registro de cotação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.users.success.disable	Sucesso ao marcar usuário como inativo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	login.error.empty_new_password	O campo "nova senha" não pode ser vazio	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245	Título principal	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.labels.popup.description	Selecione em qual etiqueta deseja iniciar a impressão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.reservation.button.delete	Excluir	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.subfield.p	Nome da parte - seção da obra	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.custom.user_field.email	Email	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.subfield.n	Número da parte - seção da obra	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.subfield.h	Meio	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.111.indicator.1.1	nome da jurisdição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.111.indicator.1.2	nome na ordem direta	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.circulation_reservation_list	Listar reservas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.cataloging_bibliographic_move	Mover registro bibliográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.type.biblio	Registro bibliográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.change_status.cancel	O Cartão será cancelado e estará indisponível para uso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_status.blocked	Bloqueado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.order	Ordenar por	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configurations.error.file_not_found	Arquivo não encontrado.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.source_search_title	Importar registros a partir de uma pesquisa Z39.50	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.reservation.expiration_date	Data de expiração da reserva	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.field.state	Estado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.title.general.subtitle	Subtítulo da biblioteca	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.upload_popup.uploading	Enviando arquivo...	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.error.save	Falha ao salvar o fornecedor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.670.subfield.a	Nota de origem do termo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.upload_popup.title	Abrindo Arquivo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.database.main_full	Base Principal	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.page_help	<p>A rotina de Pedidos permite o cadastramento e pesquisa de pedidos (compras) realizados com os fornecedores cadastrados. Para cadastrar um novo Pedido, deve-se selecionar um Fornecedor e uma Cotação previamente cadastrados, assim como entrar dados como Data de Vencimento e dados da Nota Fiscal.</p>\n<p>A pesquisa buscará cada um dos termos digitados nos campos <em>Número do Registro do Pedido, Nome Fantasia do Fornecedor, e Autor ou Título da Requisição</em>.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.555.subfield.3	Materiais especificados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.error.couldnt_restore_backup	Não foi possível restaurar o backup selecionado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.administration_configurations	Gerenciar configurações	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.holdings_available	Disponíveis	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.group.custom	Relatório Personalizado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.biblio_reservation	Reservas por registro bibliográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.acquisition_request_save	Salvar registro de requisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.accesscards.return.error	Falha ao devolver o Cartão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.fine.failure_pay_fine	Falha ao pagar multa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.indicator.2.2	entrada analítica	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.circulation_access	Controle de Acesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.login_change_password	Trocar senha	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.210	Título Abreviado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.856.subfield.y	Link em texto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	field.error.date	O valor preenchido não é uma data válida. Utilize o formato {0}	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.856.subfield.u	URI	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.accesscards.lend.error	Falha ao vincular o Cartão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_field.login	Login	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.856.subfield.d	Caminho	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.upload_popup.processing	Processando...	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.no_data	Não existem dados para gerar este relatório	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.555.subfield.a	Nota de índice cumulativo e remissivo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.555.subfield.b	Fonte disponível	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.z3950.success.update	Servidor z39.50 atualizado com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.555.subfield.c	Grau de controle	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.856.subfield.f	Nome do arquivo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.555.subfield.d	Referência bibliográfica	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.321.subfield.b	Datas da periodicidade anterior	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.321.subfield.a	Peridiocidade Anterior	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.type.authorities	Autoridades	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.555.subfield.u	Identificador uniforme de recursos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.searches	Relatório de Total de Pesquisas por Período	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.open_item_button	Abrir registro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.administration_configurations	Configurações	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.041.indicator.1.0	Item não é e não inclui tradução	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.tabs.reservations	Reservas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.cancel	Cancelar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	field.error.min_length	Este campo deve possuir no mínimo {0} caracteres	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.041.indicator.1.1	Item é ou inclui tradução	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.indicator.2._	nenhuma informação fornecida	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.cataloging_labels	Impressão de Etiquetas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.distributed.isbn	ISBN	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.option.title	Título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_cards.page_help	<p>O módulo <strong>"Impressão de Carteirinhas"</strong> permite gerar as etiquetas de identificação dos leitores da biblioteca.</p>\n<p>É possível gerar as carteirinhas de um ou mais leitores em uma única impressão, utilizando a pesquisa abaixo.</p>\n<p>Após encontrar o(s) leitor(es), use o botão <strong>"Selecionar usuário"</strong> para adicioná-los à lista de impressão de carteirinhas. Você poderá fazer diversas pesquisas, sem perder a seleção feita anteriormente. Quando estiver satisfeito com a seleção, clique no botão <strong>"Imprimir carteirinhas"</strong>. Será possível selecionar a posição da primeira carteirinha na folha de etiquetas.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.circulation_save	Salvar registro de usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.field.info	Observações	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.no_attachments	Este registro não possui arquivos digitais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.error.save	Falha ao salvar a Requisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.750.subfield.z	Subdivisão geográfica	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.505.subfield.a	Notas de conteúdo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.750.subfield.x	Subdivisão geral	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.750.subfield.y	Subdivisão cronológica	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.holding.confirm_delete_record_title	Excluir registro de exemplar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.button.print_lending_receipt	Imprimir recibo de empréstimo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.field.quotation_date	Data do Pedido de Cotação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.100.indicator.1	Forma de entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.lending.error.holding_is_lent	O exemplar selecionado já está emprestado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.database.trash	Lixeira	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.lendings_top	Livros mais emprestados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.field.id	N&ordm; do registro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.field.address_number	Número	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.250	Edição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.255	Dado matemático cartográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.256	Características do arquivo de computador	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.custom.user_field.obs	Observações	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.750.indicator.2.0	Library of Congress Subject Heading	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.help	Ajuda	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.258	Informação sobre material filatélico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.257	País da entidade produtora	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.material_type.articles	Artigo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.user_not_found	Não foi possível encontrar o usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.150.subfield.y	Subdivisão cronológica adotada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.150.subfield.x	Subdivisão geral adotada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.title.unit_value	Valor Unitário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.750.indicator.2.4	Source not specified	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.150.subfield.z	Subdivisão geográfica adotada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.lending.error.holding_unavailable	O exemplar selecionado está indisponível para empréstimos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.indexing_groups.author	Autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.button_full	Gerar backup completo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.accession_number.full	Relatório completo de Tombo Patrimonial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.start_number	Número inicial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240	Título uniforme	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243	Título Convencionado Para Arquivamento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.user_lendings	Empréstimos Ativos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.670.subfield.b	Informações encontradas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.670.subfield.a	Nome retirado de	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.700.indicator.2	Tipo de entrada secundária	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.page_help	<p>A rotina de Cotações permite o cadastramento e pesquisa de cotações (orçamentos) realizadas com os fornecedores cadastrados. Para cadastrar uma nova Cotação, deve-se selecionar um Fornecedor e uma Requisição previamente cadastrados, assim como entrar dados como o valor e a quantidade de obras cotadas.</p>\n<p>A pesquisa buscará cada um dos termos digitados nos campos <em>Número do Registro de Cotação ou Nome Fantasia do Fornecedor</em>.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.accesscards.bind_card	Vincular Cartão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.description.search.distributed_search_limit	Esta configuração representa a quantidade máxima de resultados que serão encontrados em uma pesquisa distribuída. Evite o uso de um limite muito elevado pois as buscas distribuídas levarão muito tempo para retornar os resultados pesquisados.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.100.indicator.1.3	nome de família	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.confirm_delete_record_question.forever	Você realmente deseja excluir este registro de fornecedor?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.success.update	Cartão salvo com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.856.subfield.u	URI	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.856.subfield.y	Link em texto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.publication_year	Ano de publicação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.no_backups_found	Nenhum backup encontrado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.printer_type.printer_40_columns	Impressora 40 colunas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.856.subfield.d	Caminho	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.515.subfield.a	Nota de Peculiaridade na Numeração	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.circulation_delete	Excluir registro de usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.user_type.field.name	Tipo de Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.856.subfield.f	Nome do arquivo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.949	Tombo patrimonial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.947	Informação da Coleção	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.611.indicator.1	Forma de entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.groups.circulation	Circulação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.150.subfield.a	Termo tópico adotado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.button.move_records	Mover Registros	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.holding.accession_number	Tombo patrimonial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.150.subfield.i	Qualificador	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.payment_date	Data de Pagamento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_field.status	Situação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.circulation_print_user_cards	Imprimir carteirinhas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.error.no_valid_terms	A pesquisa especificada não contém termos validos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.users_with_late_lendings	Listar apenas usuários com empréstimos em atraso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.field.delivered_quantity	Quantidade recebida	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.title.holdings_full	Relatório completo de Tombo Patrimonial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.page_help	<p>Para realizar um empréstimo você deverá selecionar o leitor para o qual o empréstimo será realizado e, em seguida, selecionar o exemplar que será emprestado. A pesquisa pelo leitor pode ser feita por nome, matrícula ou outro campo previamente cadastrado. Para encontrar o exemplar, utilize seu Tombo Patrimonial.</p><p>Devoluções podem ser feitas através do leitor selecionado ou diretamente pelo Tombo Patrimonial do exemplar que está sendo devolvido ou renovado.</p><p>O prazo para devolução é calculado de acordo com o tipo de usuário, configurado pelo menu <strong>Administração</strong> e definido durante o cadastro do leitor.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.user_type.field.fine_value	Valor da Multa por atrasos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.distributed_search	Pesquisa Distribuída	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.cataloging_authorities	Autoridades	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.acquisition_quotation_list	Listar cotações	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_cards.paper_description	{paper_size} {count} etiquetas ({height} mm x {width} mm)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.fieldset.order	Ordenação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.selected_records_plural	{0} Valores Adicionados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.700.indicator.1	Forma de entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.indicator.1.2	2 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.indicator.1.3	3 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.indicator.1.0	Nenhum caractere a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.indicator.1.1	1 caractere a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.indicator.1.6	6 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.indicator.1.7	7 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.indicator.1.4	4 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.indicator.1.5	5 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.group.circulation	Circulação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.holding.availability.unavailable	Indisponível	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.title.author	Autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.indicator.1.8	8 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.title	Título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.indicator.1.9	9 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.field.delivery_time	Prazo de entrega (Prometido)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.description.general.currency	Esta configuração representa a moeda que será utilizada em multas e no módulo de aquisição.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.database_main	Principal	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.record.success.move	Registros movidos com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.acquisition_quotation	Cotações	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.holding.availability	Disponibilidade	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.reservation.delete_success	Reserva excluída com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.029.subfield.a	Número do ISNM	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.created_between	Catalogado entre	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.confirm_delete_record_title.forever	Excluir registro de cotação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.260	Publicação, edição. Etc.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.confirm_delete_record_question.forever	Você realmente deseja excluir este registro de Pedido?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.fieldset.title.values	Valores	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.confirm_delete_record.forever	Ele será excluído permanentemente do sistema e não poderá ser recuperado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.913	Código local	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.reindex.title	Reindexação da Base de Dados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.simple_term_title	Preencha os termos da pesquisa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.lending.error.blocked_user	O leitor selecionado está bloqueado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.records_found_singular	{0} registro encontrado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.710.indicator.2._	nenhuma informação fornecida	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.error.delete	Falha ao exluir o fornecedor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.type.do_not_import	Não importar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.indicator.1	Número de caracteres a serem desprezados na alfabetação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.indicator.2	Tipo de entrada secundária	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.error.delete.user_has_accesscard	Este usuário possui cartão de acesso em uso.  Realize a devolução do cartão antes de excluir este usuário.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.111.indicator.1	Forma de entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.field.created_by	Responsável	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_130	Obra Anônima	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	language_name	Português (Brasil)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_534	Notas de fac-símile	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.360.subfield.z	Subdivisão geográfica adotada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.360.subfield.y	Subdivisão cronológica adotada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.confirm_delete_record_title	Excluir registro de Pedido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.360.subfield.x	Subdivisão geral adotada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.reservations	Relatório de Reservas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.reservation_date	Data da Reserva	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.vocabulary.term.up	Termo Use Para (UP)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_520	Notas de resumo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.411.subfield.a	Nome do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_521	Notas de público alvo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.title.quantity	Quantidade	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.users.success.unblock	Usuário desbloqueado com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.user.open_item_button	Abrir cadastro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.vocabulary.simple_search	Pesquisa de Vocabulário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.page_help	<p>A rotina de Relatórios permite a geração e impressão de diversos relatórios disponibilizados pelo Biblivre. Os relatórios disponíveis se dividem entre as rotinas de Aquisição, Catalogação e Circulação.</p>\n<p>Alguns dos relatórios disponíveis possuem filtros, como Base Bibliográfica, ou Período, por exemplo. Para outros, basta selecionar o relatório e clicar em "Emitir Relatório".</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_110	Autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.tabs.form	Cadastro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_111	Autor Evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.100.indicator.1.1	sobrenome simples ou composto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.100.indicator.1.2	sobrenome composto (obsoleto)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.holdings_count	Qtdd. Exemplares	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.clear	Limpar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.100.indicator.1.0	prenome simples ou composto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.selected_records_singular	{0} Valor Adicionado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.vocabulary.term.tg	Termo Geral (TG)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.vocabulary.term.te	Termo Específico (TE)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.preview	Pré visualização	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.490	Indicação de série	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.vocabulary.confirm_delete_record_title	Excluir registro de vocabulário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.vocabulary.term.ta	Termo Associado (VT / TA)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.modified	Atualizado em	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.521.subfield.a	Notas de público alvo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.search	Pesquisa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.unclassified	<Não classificado>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.administration_translations	Gerenciar traduções	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.501.subfield.a	Notas iniciadas com a palavra "com"	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.600.indicator.1	Forma de entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.260.subfield.b	Nome do editor, publicador, etc.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.260.subfield.c	Data de publicação, distribuição, etc.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.user.search	Digite o nome ou matrícula do Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.260.subfield.e	Nome do impressor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.error.invalid_search_parameters	Os parâmetros desta pesquisa não estão corretos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.title.search.results_per_page	Resultados por página	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.author_type.select_author_type	Selecione o tipo de autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.260.subfield.a	Local de publicação, distribuição, etc.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_500	Notas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.confirm_delete_record.trash	Ele será movido para a base de dados "lixeira"	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.260.subfield.f	Informações adicionais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.260.subfield.g	Data de impressão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_502	Nota de tese	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_505	Notas de conteúdo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_504	Notas de bibliografia	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_506	Notas de acesso restrito	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.circulation_lending_list	Listar empréstimos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.520.subfield.a	Notas de resumo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.reservation.record_reserved_to_the_following_readers	Este registro está reservado para os seguintes leitores	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.change_password.new_password	Nova senha	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	login.error.password_not_matching	Os campos "nova senha" e "repita a nova senha" devem ser iguais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.110.subfield.b	Unidades subordinadas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.110.subfield.c	Local de realização do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.110.subfield.d	Data da realização do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.subject	Assunto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configurations.save.success	Configurações alteradas com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.110.subfield.l	Língua do texto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	z3950.adresses.list.no_address_found	Nenhum Servidor Z39.50 encontrado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.search_limit	A pesquisa realizada encontrou {0} registros, porém apenas os {1} primeiros serão exibidos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.110.subfield.n	Número da parte - seção da obra - ordem do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.error.generate	Falha ao gerar o relatório. Verifique o preenchimento do formulário.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.record.error.save	Falha ao salvar o Registro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_100	Autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.110.subfield.a	Nome da entidade ou do lugar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.error.unblock	Falha ao desbloquear o Cartão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.acquisition_order_delete	Excluir registro de pedido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.confirm_cancel_editing.2	Todas as alterações serão perdidas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.ok	Ok	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.confirm_cancel_editing.1	Você deseja cancelar a edição deste registro de requisição?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.vocabulary.indexing_groups.total	Total	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.authorities_670	Nome retirado de	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.field_count	Contagem do campo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.z3950.confirm_cancel_editing_title	Cancelar edição do Servidor Z39.50	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.362.indicator.1.1	Nota não formatada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.362.indicator.1.0	Estilo formatado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.error.invalid_file	Arquivo inválido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.no	Não	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.search_button	Pesquisar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.z3950.confirm_cancel_editing.2	Todas as alterações serão perdidas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.z3950.confirm_cancel_editing.1	Você deseja cancelar a edição deste Servidor Z39.50?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.circulation_access_control_bind	Gerenciar controle de acesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.080.subfield.2	Número de edição da CDU	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.cataloging_print_labels	Imprimir etiquetas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.confirm_cancel_editing.1	Você deseja cancelar a edição deste registro de fornecedor?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.610.indicator.1.0	prenome simples ou composto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.confirm_cancel_editing.2	Todas as alterações serão perdidas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_cards.popup.title	Formato das etiquetas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.610.indicator.1.3	nome de família	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.610.indicator.1.1	sobrenome simples ou composto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.610.indicator.1.2	sobrenome composto (obsoleto)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.reindex.button_authorities	Reindexar base de autoridades	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.option.author	Autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.authorities.simple_search	Pesquisa de Autoridades	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.520.subfield.u	URI	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.user_current_lending_list	Exemplares emprestados a este leitor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.210.subfield.b	Qualificador	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.210.subfield.a	Título Abreviado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.255.subfield.a	Escala	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.cataloging_label	Etiquetas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.vocabulary_680	Nota de Escopo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_700	Autor secundário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.vocabulary_685	Nota de Histórico ou Glossário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.acquisition_order_list	Listar pedidos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.migration.groups.access_control	Cartões de acesso e Controle de acesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.distributed.query_placeholder	Preencha os termos da pesquisa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.distributed.any	Qualquer	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.user_type.field.description	Descrição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.accesscards.lend.success	Cartão vinculado com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.change_status.title.unblock	Desbloquear Cartão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.button.inactive	Marcar como inativo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.740.indicator.1	Número de caracteres a serem desprezados na alfabetação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.740.indicator.2	Tipo de entrada secundária	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.topographic	Relatório Topográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.title.title	Título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.indexing_groups.year	Ano	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.user_type.field.reservation_limit	Limite de reservas simultâneas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.users.failure.unblock	Falha ao desbloquear o Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.field.expiration_date	Data de Validade da Cotação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.change_password.submit_button	Trocar Senha	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.indicator.2	Número de caracteres a serem desprezados na alfabetação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.database.work	Trabalho	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.indicator.1	Gera entrada secundária na ficha	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.translations.upload_popup.processing	Processando...	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.vocabulary.indexing_groups.up_term	Termo Use Para (UP)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.750.indicator.2.4	Source not specified	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.button.block	Bloquear	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.reindex.button_vocabulary	Reindexar base de vocabulário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.400	Outra Forma do nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.administration_accesscards_delete	Excluir cartões de acesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.translations.download.field.languages	Idioma	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.error.block	Falha ao bloquear o Cartão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.100.subfield.d	Datas associadas ao nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.100.subfield.c	Título e outras palavras associadas ao nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.vocabulary_670	Origem das Informações	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.410	Outra Forma do nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.tabs.fines	Multas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.100.subfield.q	Forma completa do nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.expected_date	Data prevista	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.success.delete	Cartão excluído com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.button.unavailable	Indisponível	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.630.indicator.1	Número de caracteres a serem desprezados na alfabetação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	digitalmedia.error.file_could_not_be_saved	O arquivo enviado não pôde ser salvo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.database.private	Privativa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.user_id	Matrícula	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.411	Outra Forma do nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.750.indicator.2.0	Library of Congress Subject Headings	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.100.subfield.a	Sobrenome e/ou prenome do autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.100.subfield.b	Numeração que segue o prenome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_590	Notas locais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.600.indicator.1.0	prenome simples ou composto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.daily_fine	Multa diária	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.600.indicator.1.1	sobrenome simples ou composto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.600.indicator.1.2	sobrenome composto (obsoleto)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.600.indicator.1.3	nome de família	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.advanced_search	Pesquisa Avançada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.label_full	Backup completo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.description.general.title	Esta configuração representa o nome da biblioteca, que será exibido no topo das páginas do Biblivre e nos relatórios.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.title.search.result_limit	Limite de resultados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.custom.user_field.gender	Gênero	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.empty_lending_list	Este leitor não possui exemplares emprestados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.acquisition_supplier	Fornecedores	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.access_control.card_not_found	Cartão não encontrado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.usertype.confirm_cancel_editing_title	Cancelar edição do Tipo de Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.confirm_cancel_editing_title	Cancelar inclusão de Cartões de Acesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.confirm_delete_record_question.forever	Você realmente deseja excluir o Login do Usuário?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.subfield.l	Língua do texto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.distributed.no_servers	Não é possível realizar uma pesquisa Z39.50 pois não existem bibliotecas remotas cadastradas. Para solucionar este problema, cadastre os servidores Z39.50 das bibliotecas de interesse na opção <em>"Servidores Z39.50"</em> dentro de <em>"Administração"</em> no menu superior. Para isto é necessário um nome de <strong>usuário</strong> e <strong>senha</strong>.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.editor	Editora	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.source_file_title	Importar registros a partir de um arquivo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.users.failure.block	Falha ao bloquear o Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.450	UP (remissiva para TE não usado)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.045.subfield.b	Período de tempo formatado de 9999 a.C em diante	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.045.subfield.a	Código do período de tempo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	digitalmedia.error.no_file_uploaded	Nenhum arquivo foi enviado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.045.subfield.c	Período de tempo formatado anterior a 9999 a.C.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.210.indicator.2.0	Outro título abreviado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.days_late	Dias de atraso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.error.order_not_found	Não foi possível encontrar o pedido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.holding_lent_to_the_following_reader	Este exemplar está emprestado para o leitor abaixo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_555	Notas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.650.subfield.a	Assunto tópico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.accesscards.unbind_card	Devolver Cartão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.sort_by	Ordenar por	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permission.error.create_login	Erro ao criar login de usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.210.indicator.1.0	Não gerar entrada secundária de título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.z3950.field.collection	Coleção	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.button.delete	Excluir	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_status.pending_issues	Possui pendências	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.210.indicator.1.1	Gerar entrada secundária de título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.title	Relatórios	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.reindex.wait	Dependendo do tamanho da base de dados, esta operação poderá demorar. O biblivre ficará indisponível durante o processo, que pode durar até 15 minutos.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.field.deadline_date	Data de Vencimento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_651	Assunto geográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_650	Assunto tópico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852	Informações sobre a localização	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.option.database.work	Trabalho	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.administration	Administração	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	login.error.login_already_exists	Este login já existe. Escolha outro nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.856	Localização de obras por meio eletrônico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.field.requester	Requerente	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	format.datetime	dd/MM/yyyy HH:mm	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.title	Título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.button.new_holding	Novo exemplar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.field.publisher	Editora	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.error.no_card_found	Nenhum cartão encontrado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.650.subfield.x	Subdivisão geral	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.650.subfield.y	Subdivisão cronológico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	login.access_denied	Acesso negado. Usuário ou senha inválidos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.650.subfield.z	Subdivisão geográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.reindex.success	Reindexação concluída com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.534.subfield.a	Notas de fac-símile	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.subfield.p	Nome da parte - seção da obra	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.users.success.block	Usuário bloqueado com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.circulation_lending_lend	Realizar empréstimos de obras	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.subfield.n	Número da parte - seção da obra	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.411	Outra forma do nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.error.select_reader_first	Para emprestar um exemplar você precisa, primeiramente, selecionar um leitor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.subfield.k	Subcabeçalhos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.indexing_groups.all	Qualquer campo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.labels.button.print_labels	Imprimir etiquetas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.subfield.g	Informações adicionais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.subfield.f	Data de edição do item que está sendo processado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.year	Ano	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.subfield.d	Data que aparece junto ao título uniforme na entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.subfield.a	Título uniforme	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_630	Assunto título uniforme	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.administration_indexing	Gerenciar indexação da base de dados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.685.subfield.i	Texto explicativo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.holding.confirm_delete_record.forever	Ele será excluído permanentemente do sistema e não poderá ser recuperado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.button.save_as_new	Salvar como novo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.reservation.reserve_success	Reserva efetuada com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.z3950.page_help	<p>A rotina de Servidores Z39.50 permite o cadastramento e pesquisa dos Servidores utilizados pela rotina de Pesquisa Distribuída. Para realizar o cadastramento serão necessários os dados da Coleção Z39.50, assim como endereço URL e porta de acesso.</p>\n<p>Ao acessar essa rotina, o Biblivre listará automaticamente todos os Servidores previamente cadastrados.  Você poderá então filtrar essa lista, digitando o <em>Nome</em> de um Servidor que queira encontrar.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tabs.form	Formulário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configurations.error.value_must_be_boolean	O valor deste campo deve ser verdadeiro ou falso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.110.indicator.1.2	nome na ordem direta	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	login.error.invalid_password	O campo "senha atual" não confere com a sua senha	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.change_password.title	Troca de Senha	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.confirm_delete_record_question	Você realmente deseja excluir este registro de autoridade?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.110.indicator.1.0	nome invertido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.110.indicator.1.1	nome da jurisdição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.490.indicator.1.0	Título não desdobrado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.490.indicator.1.1	Título desdobrado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.541.subfield.3	Especificações do material	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.590.subfield.a	Notas locais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.acquisition_request_list	Listar requisições	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.invalid_pg_dump_path	Caminho inválido. O Biblivre não será capaz de gerar backups já que o arquivo <strong>pg_dump</strong> não foi encontrado.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.holdings.title	Pesquisar Exemplar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.accession_number	Relatório de Tombo Patrimonial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.description.cataloging.accession_number_prefix	O tombo patrimonial é o campo que identifica unicamente um exemplar. No Biblivre, a regra de formação para o tombo patrimonial depende do ano de aquisição do exemplar, da quantidade de exemplares adquiridos no ano e do prefixo do tombo patrimonial. Este prefixo é o termo que será inserido antes da numeração de ano, no formato <prefixo>.<ano>.<contador> (Ex: Bib.2014.7).	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.confirm_delete_record.forever	Ele será excluído permanentemente do sistema e não poderá ser recuperado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.111.indicator.1.1	nome da jurisdição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.111.indicator.1.2	nome na ordem direta	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.111.indicator.1.0	nome invertido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.previous	Anterior	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.administration_usertype_list	Listar tipos de usuários	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_cards.button.select_page	Selecionar usuários desta página	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_610	Assunto entidade coletiva	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.administration_user_types	Tipos de Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_611	Assunto evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select_report	Selecione um Relatório	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.680	Nota de escopo (NE)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.description.general.business_days	Esta configuração representa os dias de funcionamento da biblioteca e será usada pelos módulos de empréstimo e reserva. O principal uso desta configuração é evitar que a devolução de um exemplar seja agendada para um dia em que a biblioteca está fechada.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.wait	Aguarde	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.685	Nota de histórico ou glossário (GLOSS)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.users	Usuários	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.circulation	Circulação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.user_deleted	Usuário excluído do sistema	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.cataloging_bibliographic	Bibliográfica	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.fieldset.cataloging	Pesquisa Bibliográfica	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.field.supplier_number	CNPJ	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.670	Nota de origem do termo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.reindex.error.invalid_record_type	Tipo de registro em branco ou desconhecido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.error.existing_card	O Cartão ja existe	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.411.subfield.a	Nome do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.repeat_password	Repetir senha	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.confirm_delete_record_title.forever	Excluir registro de Pedido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.help	Ajuda	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.authorities.page_help	<p>A pesquisa de autoridades permite recuperar informações sobre os autores presentes no acervo desta biblioteca, caso catalogados.</p>\n<p>A pesquisa buscará cada um dos termos digitados nos seguintes campos: <em>{0}</em>.</p>\n<p>As palavras são pesquisadas em sua forma completa, porém é possível usar o caractere asterisco (*) para buscar por palavras incompletas, de modo que a pesquisa <em>'brasil*'</em> encontre registros que contenham <em>'brasil'</em>, <em>'brasilia'</em> e <em>'brasileiro'</em>, por exemplo. Aspas duplas podem ser usadas para encontrar duas palavras em sequência, de modo que a pesquisa <em>"meu amor"</em> encontre registros que contenham as duas palavras juntas, mas não encontre registros com o texto <em>'meu primeiro amor'</em>.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.add_field	Adicionar termo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.vocabulary_750	Termo Tópico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	login.goodbye	Até logo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.labels.button.select_page	Selecionar exemplares desta página	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.user_type.error.no_user_type_found	Nenhum Tipo de Usuário encontrado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.user_type.field.lending_time_limit	Prazo de empréstimo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.tabs.lendings	Empréstimos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tabs.marc	MARC	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_600	Assunto pessoa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.groups.login	Login	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.description.general.subtitle	Esta configuração representa um subtítulo para a biblioteca, que será exibido no topo das páginas do Biblivre, logo abaixo do <strong>Nome da biblioteca</strong>. Esta configuração é opcional.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.360.subfield.y	Subdivisão cronológica adotada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.360.subfield.x	Subdivisão geral adotada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.selected_records_singular	{0} Valor Adicionado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.360.subfield.z	Subdivisão geográfica adotada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.material_type.map	Mapa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.711.subfield.e	Nome de subunidades do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.711.subfield.g	Informações adicionais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.711.subfield.a	Nome do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_cards.selected_records_singular	{0} usuário selecionado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.711.subfield.c	Local de realização do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.711.subfield.d	Data da realização do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.711.subfield.n	Número de ordem do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.711.subfield.k	Subcabeçalhos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.fieldset.user	Pesquisa de Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.711.subfield.t	Título da obra junto a entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.490.subfield.a	Título da série	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.490.subfield.v	Número do volume ou designação sequencial da série	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.080.subfield.a	Número de Classificação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.830.indicator.2	Número de caracteres a serem desprezados na alfabetação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configurations.error.value_is_required	O preenchimento deste campo é obrigatório	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.360.subfield.a	Termo tópico adotado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.field.area	Bairro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.success.save	Requisição incluída com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.indicator.1.3	3 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.group.cataloging	Catalogação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.indicator.1.2	2 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.indicator.1.5	5 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.indicator.1.4	4 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.indicator.1.7	7 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.indicator.1.6	6 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.user_list_by_type	Lista de Usuários Por Tipo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.indicator.1.9	9 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.button.import_all	Importar todas as páginas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.indicator.1.8	8 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.lendings_count	Total de Livros emprestados no período	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.registered_between	Cadastrado entre	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.title.reservation	Relatório de Reservas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.end_date	Data Final	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.indicator.1.1	1 caractere a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.indicator.1.0	Nenhum caractere a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.subfield.p	Nome da parte - seção da obra	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.error.you_cannot_delete_yourself	Você não pode excluir-se ou marcar-se como inativo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.indicator.1.0	Não gera entrada para o título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.button.list_all	Listar Todos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.indicator.1.1	Gera entrada para o título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.prefix	Prefixo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.custom_count	Contagem de Registros Bibliográficos por Campo Marc	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	error.invalid_handler	Não foi possível encontrar um handler para esta ação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.material_type	Tipo de material	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.containing_text	Contendo o texto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.migration.button.migrate	Importar dados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.expected_return_date	Data prevista para devolução	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.indexing_groups.author	Autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.041.indicator.1	Indicação de tradução	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.cataloging_vocabulary_delete	Excluir registro de vocabulário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.database.work_full	Base de Trabalho	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tabs.holdings	Exemplares	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.labels.paper_description	{paper_size} {count} etiquetas ({height} mm x {width} mm)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.subfield.b	Data que aparece junto ao título uniforme na entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.search_bibliographic	Bibliográfica	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.subfield.a	Título uniforme	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.success.delete	Requisição excluída com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.page_help	<p>A rotina de Fornecedores permite o cadastramento e pesquisa de fornecedores. A pesquisa buscará cada um dos termos digitados nos campos <em>Nome Fantasia, Razão Social ou CNPJ</em>.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.subfield.g	Informações adicionais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.subfield.f	Data do trabalho	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.530.subfield.a	Notas de disponibilidade de forma física	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.subfield.k	Subcabeçalhos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.requester	Requerente	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.administration_maintenance	Manutenção	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.subfield.n	Número da parte - seção da obra	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.subfield.l	Língua do texto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.no_lendings	Este usuário não possui empréstimos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.title.author	Autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.field.id	N&ordm; do registro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.111.subfield.a	Nome do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.111.indicator.1	Forma de entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.circulation_reservation_reserve	Realizar reservas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_699	Assunto local	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.confirm_cancel_editing_title	Cancelar edição de registro de autoridade	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.access_control.card_available	Este cartão está disponível	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.400.subfield.a	Sobrenome e/ou Prenome do Autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	label.login	Entrar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.title	Permissões	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.button.import_this_page	Importar registros desta página	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configurations.error.invalid_writable_path	Caminho inválido. Este diretório não existe ou o Biblivre não possui permissão de escrita.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.541.subfield.d	Data da aquisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.541.subfield.e	Número atribuído a aquisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.541.subfield.b	Endereço	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.541.subfield.c	Forma de aquisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.541.subfield.a	Nome da fonte	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.740.indicator.1.1	1 caractere a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.740.indicator.1.2	2 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.users.success.save	Usuário incluído com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.reindex.description.4	Problemas na pesquisa, onde registros cadastrados não são encontrados.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.740.indicator.1.0	Nenhum caractere a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.541.subfield.f	Proprietário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.541.subfield.h	Preço de compra	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.740.indicator.1.9	9 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.740.indicator.1.7	7 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.740.indicator.1.8	8 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.reindex.description.2	Alteração na configuração de campos buscáveis;	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.740.indicator.1.5	5 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.541.subfield.o	Tipo de unidade	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.830	Entrada secundária - Série - Título Uniforme	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.reindex.description.3	Importação de registros de versões antigas do Biblivre; e	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.change_status.uncancel	O Cartão será recuperado e estará disponível para uso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.740.indicator.1.6	6 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.541.subfield.n	Quantidade de itens adquiridos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.740.indicator.1.3	3 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.reindex.description.1	A reindexação da base de dados é o processo no qual o Biblivre analisa cada registro cadastrado, criando índices em certos campos para que a pesquisa neles seja possível. É um processo demorado e que deve ser executado apenas nos casos específicos abaixo:<br/>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.306.subfield.a	Tempo de duração	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.740.indicator.1.4	4 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.active_lendings	Empréstimos ativos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.button.remove_login	Remover Login	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.reservation.button.select_reader	Selecionar leitor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.subfield.a	Localização	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.subfield.b	Sub-localização ou coleção	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.subfield.c	Localização na estante	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configurations.error.save	Não foi possível salvar as configurações	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.subfield.e	Endereço postal	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.label.example	ex.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.reservation.button.reserve	Reservar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.500.subfield.a	Notas gerais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.field.quantity	Quantidade de exemplares	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.administration_z3950_servers	Servidores Z39.50	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.title.quantity	Quantidade	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	login.error.same_password	A nova senha deve ser diferente da senha atual	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.usertype.confirm_cancel_editing.1	Você deseja cancelar a edição deste Tipo de Usuário?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.usertype.confirm_cancel_editing.2	Todas as alterações serão perdidas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.field.code	Cartão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.user_type.success.save	Tipo de Usuário incluído com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.400.subfield.a	Sobrenome e/ou Prenome do autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.suffix	Sufixo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.360.subfield.a	Termo tópico adotado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.late_lendings	Relatório de Empréstimos em Atraso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.subfield.z	Nota pública	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.856	Localização de obras por meio eletrônico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.710.indicator.2.2	entrada analítica	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.indexing_groups.other_name	Outras formas do nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.title.general.currency	Moeda	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.subfield.q	Condição física da parte	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.subfield.x	Nota interna	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.field.delivered	Pedido recebido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.group.acquisition	Aquisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.subfield.u	URI	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.field.supplier_select	Selecione um Fornecedor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.subfield.j	Número de controle na estante	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.button.select_page	Selecionar registros desta página	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.on_the_field	No campo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.subfield.n	Código do País	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.111.subfield.e	Nome de subunidades do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.111.subfield.c	Local de realização do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.111.subfield.d	Data da realização do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.material_type	Tipo de material	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.fieldset.contact	Contatos/Telefones	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.111.subfield.g	Informações adicionais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.111.subfield.n	Número de ordem do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.111.subfield.k	Subcabeçalhos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.labels.selected_records_plural	{0} exemplares selecionados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_400	Outra forma do nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.common.button.upload	Enviar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.362	Informação de Datas de Publicação e/ou Volume	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.360	Remissiva VT (ver também) e TA (termo relacionado ou associado)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.field.supplier_select	Selecione um Fornecedor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.shelf_location	Localização	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.700.indicator.2._	nenhuma informação fornecida	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.confirm_delete_record_question.inactive	Você realmente deseja marcar este usuário como "inativo"?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.error.couldnt_unzip_backup	Não foi possível descompactar o backup selecionado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.translations.error.dump	Não foi possível gerar o arquivo de traduções	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.confirm_delete_record_title	Excluir registro de requisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.error.invalid_database	Base de dados inexistente	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.created	Cadastrado em	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.page_help	<p>A rotina de Cartões de Acesso permite o cadastramento e pesquisa dos Cartões utilizados pela rotina de Controle de Acesso. Para realizar o cadastramento o Biblivre oferece duas opções:</p>\n<ul><li>Cadastrar Novo Cartão: utilize para cadastrar apenas um cartão de acesso;</li><li>Cadastrar Sequência de Cartões: utilize para cadastrar mais de um cartão de acesso, em sequência. Utilize o campo "Pré visualização" para verificar como serão as numerações dos cartões incluídos.</li></ul>\n<p>Ao acessar essa rotina, o Biblivre listará automaticamente todos os Cartões de Acesso previamente cadastrados.  Você poderá então filtrar essa lista, digitando o <em>Código</em> de um Cartão de Acesso que queira encontrar.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.confirm_delete_record_question	Você realmente deseja excluir este registro de Pedido?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.administration_reports	Gerar Relatórios	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.option.classification	Classificação (CDD)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.field.url	URL	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.error.no_record_found	Nenhum Registro válido encontrado no arquivo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.reservation.holdings.title	Pesquisar Registro Bibliográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.database.record_count	Registros nesta base: <strong>{0}</strong>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.confirm_delete_record_title	Excluir registro de autoridade	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.confirm_delete_record_question	Você realmente deseja excluir este registro bibliográfico?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	format.date_user_friendly	DD/MM/AAAA	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.title.holdings_creation_by_date	Relatório de Total de Inclusões de Obras por Período	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.field.complement	Complemento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.750	Termo tópico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.user_type	Tipo de Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.340	Suporte físico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.fine_popup.description	Esta devolução está em atraso e está sujeita a pagamento de multa. Verifique abaixo as informações apresentadas e confirme se a multa será adicionada ao cadastro do usuário para ser paga futuramente (Multar), se ela foi paga no momento da devolução (Pagar) ou se ela será abonada (Abonar).	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permission.success.permissions_saved	Permissões alteradas com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.343	Dados de coordenada plana	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.342	Dados de referência geospacial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_013	Informação do controle de patentes	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.added_to_list	Adicionado à lista	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.marc_popup.description	Use a caixa abaixo para alterar o MARC deste registro antes de importá-lo.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.710.indicator.1.2	nome na ordem direta	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.reindex.confirm	Deseja confirmar a reindexação da base?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.710.indicator.1.0	nome invertido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.710.indicator.1.1	nome da jurisdição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.090.subfield.b	Código do autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.090.subfield.a	Classificação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.search_vocabulary	Vocabulário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.modified	Data Cancelamento/Alteração	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.740	Entrada secundária - Título Adicional - Analítico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_410	Outra forma do nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_411	Outra forma do nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.090.subfield.d	Número do exemplar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.090.subfield.c	Edição / volume	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_020	ISBN	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.indicator.2.9	9 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.indicator.2.8	8 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.indicator.2.7	7 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_024	ISRC	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.button.print_receipt	Imprimir recibo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_022	ISSN	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.indicator.2.2	2 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.indicator.2.1	1 caractere a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.indicator.2.0	Nenhum caractere a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.indicator.2.6	6 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.indicator.2.5	5 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.indicator.2.4	4 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.362.indicator.1	Formato da data	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.240.indicator.2.3	3 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.form.remove	Remover	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.acquisition_quotation_save	Salvar registro de cotação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.field.info	Observações	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.title.orders_by_date	Relatório de Pedidos por Período	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.lend_success	Exemplar emprestado com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.holding_reservation	Reservas por serial do exemplar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.button.edit	Editar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.confirm_cancel_editing.2	Todas as alterações serão perdidas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.confirm_cancel_editing.1	Você deseja cancelar a edição deste registro de cotação?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.confirm_cancel_editing.1	Você deseja cancelar a inclusão de Cartões de Acesso?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.confirm_cancel_editing.2	Todas as alterações serão perdidas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.label_exclude_digital_media	Backup sem arquivos digitais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.administration_permissions	Logins e Permissões	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.circulation_list	Listar usuários	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.541.indicator.1	Privacidade	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.isrc_already_in_database	Já existe um registro com este ISRC na base de dados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.button.save_as_new	Salvar como novo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.610.indicator.1	Forma de entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.subfield.z	Subdivisão geográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.indexing_groups.isrc	ISRC	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.subfield.x	Subdivisão geral	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.help_about_biblivre	Sobre o Biblivre	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.subfield.y	Subdivisão cronológico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.save.success	Registros importados com successo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.confirm_cancel_editing_title	Cancelar edição de registro de fornecedor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	field.error.required	O preenchimendo deste campo é obrigatório	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.upload_popup.uploading	Enviando arquivo...	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.reservation.reserve_date	Data da reserva	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.created	Data de cadastro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permission.success.create_login	Login e permissões criados com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	error.file_not_found	Arquivo não encontrado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.043.subfield.a	Código de área geográfica	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.indexing_groups.issn	ISSN	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.reservation.reservation_count	Registros reservados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.help_about_library	Sobre a Biblioteca	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.title.administration.z3950.server.active	Servidor z39.50 local ativo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.indexing_groups.entity	Entidade	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.310.subfield.a	Periodicidade Corrente	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.310.subfield.b	Data da periodicidade corrente	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.acquisition_request_delete	Excluir registro de requisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.090	Número de chamada / Localização	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.vocabulary.indexing_groups.vt_ta_term	Termo Associado (VT / TA)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.150	TE	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.circulation_lending_return	Realizar devoluções de obras	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.users.failure.delete	Falha ao excluir usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.confirm_cancel_editing_title	Cancelar edição de registro de requisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.add_cards	Adicionar Cartões	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.cataloging_authorities_move	Mover registro de autoridade	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.description.general.pg_dump_path	Atenção: Esta é uma configuração avançada, porém importante. O Biblivre tentará encontrar automaticamente o caminho para o programa <strong>pg_dump</strong> e, exceto em casos onde seja exibido um erro abaixo, você não precisará alterar esta configuração. Esta configuração representa o caminho, no servidor onde o Biblivre está instalado, para o executável <strong>pg_dump</strong> que é distribuído junto do PostgreSQL. Caso esta configuração estiver inválida, o Biblivre não será capaz de gerar cópias de segurança.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.change_status.title.cancel	Cancelar Cartão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.confirm_move_record_description_singular	Você realmente deseja mover este registro?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.migration.groups.reservations	Reservas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.reindex.warning	Este processo pode demorar alguns minutos, dependendo da configuração de hardware do seu servidor. Durante este tempo, o Biblivre não estará disponível para a pesquisa de registros, mas voltará assim que a indexação terminar.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.user.simple_term_title	Preencha os termos da pesquisa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.receipt.title	Título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.reservation.delete_failure	Falha ao excluir a reserva	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.paid_value	Valor Total Pago	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.082.subfield.a	Número de Classificação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.button.lend	Emprestar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.913	Código local	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.acquisition	Aquisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.vocabulary_150	Termo Específico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.confirm_delete_record_question	Você realmente deseja excluir este registro de cotação?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.fieldset.database	Base de Dados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.source_search_subtitle	Selecione uma biblioteca remota e preencha os termos da pesquisa. A pesquisa retornará um limite de {0} registros. Caso não encontre o registro de interesse, refine sua pesquisa.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.clear_simple_search	Limpar resultados da pesquisa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.vocabulary_550	Termo Genérico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.confirm_delete_record_title.forever	Excluir usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.confirm_cancel_editing.1	Você deseja cancelar a edição deste registro bibliográfico?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.late_lendings_count	Total de Empréstimos em Atraso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.holding.confirm_cancel_editing_title	Cancelar edição de registro de exemplar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.confirm_cancel_editing.2	Todas as alterações serão perdidas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.subfield.a	Título uniforme atribuído ao documento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.no_records_found	Nenhum registro encontrado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.subfield.d	Data que aparece junto ao título uniforme de entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.field.receipt_date	Data do recebimento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.title.user	Relatório por Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.subfield.p	Nome da parte - Seção da obra	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.number_of_holdings	Número de Exemplares	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.database.main	Principal	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.subfield.f	Data da edição do item que está sendo processado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.field.address	Endereço	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.page_help	<p>A rotina de Requisições permite o cadastramento e pesquisa de requisições de obras. Uma requisição é um registro de alguma obra que a Biblioteca deseja adquirir, e pode ser utilizada para se realizar Cotações com os Fornecedores previamente cadastrados.</p>\n<p>A pesquisa buscará cada um dos termos digitados nos campos <em>Requerente, Autor ou Título</em>.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.no_reserves	Este usuário não possui reservas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.subfield.g	Informações adicionais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.subfield.l	Língua do texto. Idioma do texto por extenso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730.subfield.k	Subcabeçalhos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.translations.error.no_language_code_specified	O arquivo de traduções enviado não possui o identificador de idioma: <strong>*language_code</strong>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.082.subfield.2	Número de edição da CDD	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.confirm_delete_record_question.forever	Você realmente deseja excluir este registro de cotação?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.210.indicator.1	Entrada secundária de título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.210.indicator.2	Tipo de Título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.user_data	Dados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.distributed.title	Título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permission.success.password_saved	Senha alterada com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_490	Série	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.750.indicator.1.0	Nenhum nível especificado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.750.indicator.1.1	Assunto primário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.z3950.confirm_delete_record.forever	O Servidor Z39.50 será excluído permanentemente do sistema e não poderá ser recuperado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.750.indicator.1.2	Assunto secundário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_status.inactive	Inativo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.field.name	Razão Social	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.unavailable	Backup não disponível	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.fine.success_pay_fine	Multa paga com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.circulation_lending	Empréstimos e Devoluções	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.100.subfield.a	Sobrenome e/ou prenome do autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.holdings_count	Exemplares	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.100.subfield.b	Numeração que segue o prenome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.step_1_title	Selecionar origem dos dados da importação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.651.subfield.y	Subdivisão cronológico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.title.cataloging.accession_number_prefix	Prefixo do tombo patrimonial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.651.subfield.x	Subdivisão geral	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.reservation.record_list_reserved	Listar apenas registros reservados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.651.subfield.z	Subdivisão geográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.indexing_groups.event	Evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.321	Peridiocidade Anterior	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.translations.error.javascript_locale_not_available	Não existe um identificador de idioma javascript para o arquivo de traduções	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.z3950.no_server_found	Nenhum servidor z39.50 encontrado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	error.invalid_user	Usuário inválido ou inexistente	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.user_late_lendings	Empréstimos em Atraso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.migration.description	Selecione abaixo quais items deseja importar da base de dados do Biblivre 3	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.field.total_value	Valor total	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.field.supplier	Fornecedor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.020.subfield.a	Número do ISBN	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.selected_records_singular	{0} registro selecionado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.020.subfield.c	Modalidade de aquisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.button.select_reader	Selecionar leitor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.indicator.2	Tipo de ordenação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.material_type.score	Partitura	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.migration.groups.digital_media	Mídias Digitais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.100.subfield.q	Forma completa do nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.error.no_quotation_found	Nenhuma cotação encontrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.marc_field	Campo Marc	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.100.subfield.d	Datas associadas ao nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.100.subfield.c	Título e outras palavras associadas ao nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.852.indicator.1	Esquema de classificação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.field.delivery_time	Prazo de entrega (Prometido)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.authorities_100	Autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.biblivre_report_header	Relatórios Biblivre	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.option.all_digits	Todos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	field.error.digits_only	Este campo deve ser preenchido com números	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.300	Descrição física	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.change_password.repeat_password	Repita a nova senha	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.306	Tempo de duração	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.error.card_not_found	Nenhum Cartão encontrado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.change_status.question.block	Deseja realmente bloquear este Cartão?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.z3950.confirm_delete_record_title.forever	Excluir Servidor Z39.50	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.button.select_user	Selecionar Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.change_status.title.block	Bloquear Cartão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.confirm_delete_record_title.forever	Excluir Cartão de Acesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.342.indicator.1.0	Sistema de coordenada horizontal	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.change_status.unblock	O Cartão será desbloqueado e estará disponível para uso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.651.subfield.a	Nome geográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.change_status.block	O Cartão será bloqueado e estará indisponível para uso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.310	Periodicidade Corrente	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.342.indicator.1.1	Sistema de coordenada Vertical	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.circulation_access_control_list	Listar controle de acesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.user_type.success.delete	Tipo de Usuário excluído com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.database.title	Base de dados selecionada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.cataloging_vocabulary_save	Salvar registro de vocabulário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.subfield.a	Título do trabalho	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.error.existing_cards	Os seguintes Cartões já existem:	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.title.holdings_by_date	Relatório de Cadastro de Exemplares	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.subfield.l	Língua do texto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.342.indicator.2.0	Geográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.subfield.k	Subcabeçalhos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.342.indicator.2.1	Projeção de mapa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.next	Próximo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.field.quotation_select	Selecione uma Cotação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.342.indicator.2.2	Sistema de coordenadas em grid	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.342.indicator.2.3	Local planar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.342.indicator.2.4	Local	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.subfield.g	Informações adicionais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.342.indicator.2.5	Modelo geodésico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.authorities_110	Autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.lendings_current	Total de Livros ainda emprestados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.342.indicator.2.6	Altitude	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.authorities_111	Autor Evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.342.indicator.2.7	A especificar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.invalid_psql_path	Caminho inválido. O Biblivre não será capaz de gerar e restaurar backups já que o arquivo <strong>psql</strong> não foi encontrado.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.success.delete	Fornecedor excluído com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.342.indicator.2.8	Profundidade	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.change_status.question.uncancel	Deseja realmente recuperar este Cartão?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.subfield.f	Data do trabalho	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.700.subfield.l	Língua do texto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.import_popup.title	Importando Registros	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.258.subfield.b	Denominação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.700.subfield.t	Título da obra junto à entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.258.subfield.a	Jurisdição emissora	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.acquisition_supplier_list	Listar fornecedores	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.700.subfield.q	Forma completa do nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.groups.admin	Administração	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.unit_value	Valor Unitário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.author_type	Tipo de autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.records	Relatório de Inclusões de Obras por Período	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.administration_accesscards_save	Incluir cartões de acesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.700.subfield.c	Título e outras palavras associadas ao nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.700.subfield.d	Datas associadas ao nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.700.subfield.a	Sobrenome e-ou prenome do autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.700.subfield.b	Numeração que segue o prenome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.error.save	Falha ao salvar a cotação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.700.subfield.e	Relação com o documento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.confirm_delete_record.trash	Ele será movido para a base de dados "lixeira"	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_field.type	Tipo de usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.indicator.1.1	Gera entrada para o título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.title.title	Título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.243.indicator.1.0	Não gera entrada para o título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.680.subfield.a	Nota de escopo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.130.indicator.1	Número de caracteres a serem desprezados na alfabetação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field_count.description	<p>Após selecionar o campo Marc e a Ordenação, realize a pesquisa bibliográfica que servirá de base para o relatório, ou clique em <strong>Emitir Relatório</strong> para utilizar toda a base bibliográfica.</p>\n<p><strong>Atenção:</strong> Este relatório pode levar alguns minutos para ser gerado, dependendo do tamanho da base bibliográfica.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.end_number	Número final	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.modified_between	Alterado entre	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.form.hidden_subfields_singular	Exibir subcampo oculto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.z3950.error.save	Falha ao salvar o servidor z39.50	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.confirm_delete_record.trash	Ele será movido para a base de dados "lixeira"	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.administration_restore	Recuperar cópia de segurança da base de dados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.acquisition_order_save	Salvar registro de pedido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.field.quantity	Quantidade	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.translations.download.button	Baixar o idioma	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.button.edit	Editar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.label_digital_media_only	Backup de arquivos digitais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.user_type.field.reservation_time_limit	Prazo de reserva	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.600.subfield.k	Subcabeçalhos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	format.datetime_user_friendly	DD/MM/AAAA hh:mm	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.acquisition_supplier_save	Salvar registro de fornecedor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.confirm_delete_record_title.inactive	Marcar usuário como "inativo"	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.600.subfield.t	Título da obra junto a entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.operator	Operador	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.600.subfield.q	Forma completa do nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.confirm_delete_record_question.forever	Você realmente deseja excluir este registro de requisição?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_710	Autor secundário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.record_will_be_ignored	Este registro não será importado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_711	Autor secundário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configurations.error.value_must_be_numeric	O valor deste campo deve ser um número	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.600.subfield.d	Datas associadas ao nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.title.summary	Relatório de Sumário do Catálogo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.field.status	Situação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.600.subfield.a	Sobrenome e-ou prenome do autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.550	TG (termo genérico)	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_field.id	Matrícula	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.600.subfield.b	Numeração que segue o prenome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.600.subfield.c	Título e outras palavras associadas ao nome	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.confirm_remove_attachment_description	Você deseja excluir esse arquivo digital?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.user_type.simple_term_title	Preencha o Tipo de Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	warning.reindex_database	Você precisa reindexar as bases de dados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.groups.cataloging	Catalogação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.user.select_item_button	Selecionar cadastro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.advanced_search	Pesquisa Bibliográfica Avançada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.600.subfield.z	Subdivisão geográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.amount	Quantidade	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.600.subfield.x	Subdivisão geral	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.600.subfield.y	Subdivisão cronológico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.users_without_user_card	Listar apenas usuários que nunca tiveram carteirinha impressa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.confirm_remove_attachment	Excluir arquivo digital	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.confirm_delete_record_question	Você realmente deseja excluir este registro de requisição?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.041	Código da língua	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.holding.error.accession_number_unavailable	Este tombo patrimonial já está em uso por outro exemplar. Por favor, preencha outro valor ou deixe em branco para que o sistema calcule um automaticamente.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.confirm_delete_record_title.forever	Excluir registro de requisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.author_type.100	Pessoa	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.button.add	Adicionar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.change_status.title.uncancel	Recuperar Cartão	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.field.created	Data do Pedido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_730	Título uniforme	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.records_found_plural	{0} registros encontrados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.100.indicator.1	Forma de entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_080	CDU	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.translations.upload.field.user_created	Carregar traduções criadas pelo usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.holding.error.shouldnt_delete_because_holding_is_or_was_lent	Este exemplar está ou já foi emprestado e não deve ser excluído. Caso ele não esteja mais disponível, o procedimento correto é mudar sua disponibilidade para Indisponível. Se desejar mesmo assim excluir este exemplar, pressione o botão <b>"Forçar Exclusão"</b>.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.page_help	<p>O <strong>"Cadastro de Usuários"</strong> permitirá guardar informações sobre os leitores e funcionários da biblioteca para que seja possível realizar empréstimos, reservas e controlar o acesso destes usuários à biblioteca.</p>\n<p>Antes de cadastrar um usuário é recomendado verificar se ele já está cadastrado, através da <strong>pesquisa simplificada</strong>, que buscará cada um dos termos digitados no campo selecionado ou através da <strong>pesquisa avançada</strong>, que confere um maior controle sobre os usuários localizados, permitindo, por exemplo, buscar usuários com multas pendentes.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.order.selected_records_plural	{0} Valores Adicionados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.author_type.110	Entidade Coletiva	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.button.unblock	Desbloquear	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.author_type.111	Evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.710.subfield.a	Nome da entidade ou do lugar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.710.subfield.b	Unidades subordinadas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.field.edition	Número da edição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.field.city	Cidade	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.710.subfield.c	Local de realização do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.710.subfield.d	Data de realização do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.710.subfield.g	Informações adicionais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	aquisition.quotation.error.quotation_not_found	Não foi possível encontrar a cotação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.710.subfield.l	Língua do texto	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_740	Título analítico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.710.subfield.n	Número da parte - Seção da obra	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.translations.success.save	Arquivo de idiomas processado com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.110.indicator.1.1	nome da jurisdição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.110.indicator.1.0	nome invertido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.administration_translations	Traduções	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.indexing_groups.isbn	ISBN	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.110.indicator.1.2	nome na ordem direta	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.710.subfield.t	Título da obra junto a entrada	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.type.vocabulary	Vocabulário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.300.subfield.b	Material Ilustrativo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	menu.circulation_reservation	Reservas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.300.subfield.a	Número de volumes e/ou paginação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.300.subfield.c	Dimensões	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.indicator.2	Tipo de título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.option.location	Localização	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.246.indicator.1	Controle de nota/entrada secundária de título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.record.success.save	Registro incluído com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.user_type.success.update	Tipo de Usuário salvo com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.300.subfield.e	Material adicional	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.300.subfield.f	Tipo de unidade de armazenamento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.300.subfield.g	Tamanho da unidade de armazenamento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.users.failure.disable	Falha ao marcar usuário como inativo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_090	Localização	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.bibliographic.id	N&ordm; do registro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.library	Biblioteca	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.740.indicator.2.2	entrada analítica	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.estimated_fine	Multa estimada para devolução hoje	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.confirm_delete_record.forever	Ele será excluído permanentemente do sistema e não poderá ser recuperado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.040	Fonte de catalogação	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.043	Código de área geográfica	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	search.common.button.filter	Filtrar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.045	Código do período cronológico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.backup_never_downloaded	Este backup nunca foi baixado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.confirm_cancel_editing.1	Você deseja cancelar a edição deste registro de autoridade?	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.confirm_cancel_editing.2	Todas as alterações serão perdidas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_082	CDD	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.authorities.indexing_groups.total	Total	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user.fine.pending	Pendente	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.error.corrupted_backup_file	O backup selecionado não é um arquivo válido ou está corrompido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.labels.popup.title	Formato das etiquetas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.indicator.2.6	6 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.indicator.2.7	7 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.300.subfield.3	Especificação Material adicional	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.indicator.2.8	8 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.indicator.2.9	9 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.indicator.2.2	2 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.title.general.business_days	Dias de funcionamento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.indicator.2.3	3 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.indicator.2.4	4 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.555.indicator.1	Controle de constante na exibição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.indicator.2.5	5 caracteres a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.migration.title	Migração de dados do Biblivre 3	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.indicator.2.0	Nenhum caractere a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.245.indicator.2.1	1 caractere a desprezar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.select.option.bibliography	Relatório de Bibliografia do Autor	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.supplier.field.vat_registration_number	Inscrição Estadual	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.receipt.renews	Renovações	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.database.record_moved	Registro movido para a {0}	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tabs.brief	Resumo Catalográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.vocabulary.datafield.685.subfield.i	Texto explicativo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_095	Área do conhecimento do CNPq	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.button.new	Novo registro	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.029	ISNM	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.user_status.inactive	Inativo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.022	ISSN	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.material_type.nonmusical_sound	Som não musical	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.024	Outros números ou códigos normalizados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.595.subfield.b	Notas de Bibliografia, índices e/ou apêndices	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.595.subfield.a	Código da bibliografia	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.020	ISBN	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.343.subfield.a	Método de codificação da coordenada plana	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.343.subfield.b	Unidade de distância plana	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.title.circulation.lending_receipt.printer.type	Tipo de impressora para recibo de empréstimos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.111.subfield.n	Número de ordem do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.111.subfield.k	Subcabeçalhos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	login.error.user_has_login	Este usuário já possui um login	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.close	Fechar	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.711.indicator.1.2	nome na ordem direta	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.111.subfield.e	Nome de subunidades do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.711.indicator.1.1	nome da jurisdição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.111.subfield.d	Data da realização do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_041	Idioma	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.711.indicator.1.0	nome invertido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.111.subfield.c	Local de realização do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.translations.error.invalid_file	Arquivo inválido	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_043	Código geográfico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.request.success.update	Requisição salva com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.import.save.failed	Falha ao importar os Registros	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_045	Código cronológico	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.111.subfield.g	Informações adicionais	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.upload_popup.title	Enviando Arquivo	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.form	Formulário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	format.date	dd/MM/yyyy	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.111.subfield.a	Nome do evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
es	acquisition.supplier.success.delete	Proveedor excluido con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.342.indicator.2.8	Profundidad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.change_status.question.uncancel	¿Desea realmente recuperar esta Tarjeta?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.243.subfield.f	Fecha del trabajo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
pt-BR	administration.user_type.page_help	<p>A rotina de Tipos de Usuários permite o cadastramento e pesquisa dos Tipos de Usuários utilizados pela rotina de Cadastro de Usuários. Aqui são definidas informações como Limite de Empréstimos simultâneos, prazos para devolução de empréstimos e valores de multas diárias para cada tipo de usuário separadamente.</p>\n<p>Ao acessar essa rotina, o Biblivre listará automaticamente todos os Tipos de Usuários previamente cadastrados.  Você poderá então filtrar essa lista, digitando o <em>Nome</em> de um Tipo de Usuário que queira encontrar.</p>	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.accesscards.success.unblock	Cartão desbloqueado com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.013	Informação do controle de patentes	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.110	Autor - Entidade coletiva	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.111	Autor - Evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.login	Login	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.730	Entrada secundária - Título uniforme	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.949	Tombo Patrimonial	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.525.subfield.a	Nota de Suplemento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	error.invalid_parameters	O Biblivre não foi capaz de entender os parâmetros recebidos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.bibliographic.indexing_groups.title	Título	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.success.save	Cotação incluída com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.items.administration_permissions	Gerenciar permissões	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.title.late_lendings	Relatório de Empréstimos Atrasados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.configuration.description.general.backup_path	Esta configuração representa o caminho, no servidor onde o Biblivre está instalado, para a pasta onde deverão ser guardados as cópias de segurança do Biblivre. Caso esta configuração estiver vazia, as cópias de segurança serão gravadas no diretório <strong>Biblivre</strong> dentro da pasta do usuário do sistema.<br>Recomendamos que este caminho esteja associado a algum tipo de backup automático em núvem, como os serviços <strong>Dropbox</strong>, <strong>SkyDrive</strong> ou <strong>Google Drive</strong>. Caso o Biblivre não consiga guardar os arquivos no caminho especificado, os mesmos serão guardados em um diretório temporário e poderão ficar indisponíveis com o tempo. Lembre-se, um backup é a única forma de recuperar os dados inseridos no Biblivre.	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.lending.lending_count	Exemplares emprestados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.permissions.confirm_delete_record_title.forever	Excluir Login do Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.holding.datafield.541	Nota sobre a fonte de aquisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.authorities.datafield.100	Autor - Nome pessoal	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.title.user_creation_count	Total de Inclusões Por Usuário	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.700	Entrada secundária - Nome pessoal	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	common.unblock	Desbloquear	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.maintenance.backup.error.invalid_schema	A lista de backup possui uma ou mais bibliotecas inválidas	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.material_type.all	Todos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.field.requisition	Requisição	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.710	Entrada secundária - Entidade Coletiva	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.711	Entrada secundária - Evento	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.vocabulary.confirm_delete_record.forever	Ele será excluído permanentemente do sistema e não poderá ser recuperado	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	acquisition.quotation.success.delete	Cotação excluída com sucesso	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	marc.bibliographic.datafield.740.indicator.2._	nenhuma informação fornecida	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	circulation.user_cards.selected_records_plural	{0} usuários selecionados	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	administration.reports.field.lendings	Empréstimos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
pt-BR	cataloging.lending.error.limit_exceeded	O leitor selecionado ultrapassou o limite de empréstimos permitidos	2014-06-14 19:34:08.805257	1	2014-06-14 19:34:08.805257	1	f
es	marc.bibliographic.datafield.700.subfield.l	Idioma del texto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.import_popup.title	Importando Registros	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.700.subfield.t	Título de la obra junto a la entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.258.subfield.b	Denominación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.acquisition_supplier_list	Listar Proveedores	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.258.subfield.a	Jurisdicción emisora	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.700.subfield.q	Forma completa del nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.gender.1	Masculino	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.gender.2	Femenino	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.groups.admin	Administración	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.unit_value	Valor Unitario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.author_type	Tipo de autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.records	Informe de Inclusiones de Obras por Período	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.administration_accesscards_save	Incluir tarjetas de acceso	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.700.subfield.c	Título y otras palabras asociadas al nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.700.subfield.d	Fechas asociadas al nombre	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.700.subfield.a	Apellido y/o nombre de autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.page_help	<p>El <strong>"Registro de Usuarios"</strong> permitirá guardar información sobre los lectores y empleados de la biblioteca para que sea posible realizar préstamos, reservas y controlar el acceso de estos Usuarios a la biblioteca.</p>\n<p>Antes de registrar un usuario es recomendable verificar si el ya está registrado, a través de la <strong>búsqueda simplificada</strong>, que buscará cada uno de los términos digitados en el campo seleccionado o a través de la <strong>búsqueda avanzada</strong>, que otorga un mayor control sobre los Usuarios localizados, permitiendo, por ejemplo, buscar Usuarios con multas pendientes.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.author_type.110	Entidad Colectiva	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.order.selected_records_plural	{0} Valores Agregados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.author_type.111	Evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user.button.unblock	Desbloquear	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.710.subfield.a	Nombre de la entidad o del lugar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.710.subfield.b	Unidades subordinadas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.field.edition	Número de la edición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.710.subfield.c	Lugar de realización del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.field.city	Ciudad	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.710.subfield.d	Fecha de realización del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.710.subfield.g	Informaciones adicionales	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	aquisition.quotation.error.quotation_not_found	No fue posible encontrar la cotización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.710.subfield.l	Idioma del texto	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_740	Título analítico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.710.subfield.n	Número de la parte - Sección de la obra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.translations.success.save	Archivo de idiomas procesado con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.110.indicator.1.1	nombre de la jurisdicción	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.administration_translations	Traducciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.indexing_groups.isbn	ISBN	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.110.indicator.1.0	nombre invertido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.710.subfield.t	Título de la obra junto a la entrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.110.indicator.1.2	nombre en el orden directo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.type.vocabulary	Vocabulario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	menu.circulation_reservation	Reservas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.300.subfield.b	Material Ilustrativo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.300.subfield.a	Número de volumenes y/o paginación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.300.subfield.c	Dimensiones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.option.location	Localización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.indicator.2	Tipo de título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.246.indicator.1	Control de nota/entrada secundaria de título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.record.success.save	Registro incluido con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.user_type.success.update	Tipo de Usuario guardado con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.custom.user_field.phone_work	Teléfono Comercial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.300.subfield.e	Material adicional	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.300.subfield.f	Tipo de unidad de almacenamiento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.300.subfield.g	Tamaño de la unidad de almacenamiento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.users.failure.disable	Falla al marcar usuario como inactivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_090	Localización	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.bibliographic.id	N&ordm; de registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.library	Biblioteca	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.setup.upload_popup.title	Abriendo Archivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.740.indicator.2.2	entrada analítica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	multi_schema.manage.schemas.title	Lista de Bibliotecas de este Servidor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.estimated_fine	Multa estimada para devolución hoy	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.confirm_delete_record.forever	Será excluido permanentemente del sistema y no podrá ser recuperado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.migration.migrate.success	Datos importados con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.041	Código del lenguaje	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.040	Fuente de catalogación	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	search.common.button.filter	Filtrar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.043	Código de área geográfica	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.backup_never_downloaded	Este backup nunca fue descargado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.045	Código de período cronológico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.confirm_cancel_editing.1	¿Usted desea cancelar la edición de este registro de autoridad?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.confirm_cancel_editing.2	Todas las alteraciones se perderán	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_082	CDD	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.authorities.indexing_groups.total	Total	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.indicator.2.6	6 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.indicator.2.7	7 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.indicator.2.8	8 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.300.subfield.3	Especificación Material adicional	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.indicator.2.9	9 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.title.general.business_days	Días de funcionamiento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.indicator.2.2	2 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.indicator.2.3	3 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.indicator.2.4	4 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.indicator.2.5	5 caracteres a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.555.indicator.1	Control de constante en la exhibición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.migration.title	Migración de datos del Biblivre 3	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.indicator.2.0	Ningún carácter a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.245.indicator.2.1	1 carácter a despreciar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.select.option.bibliography	Informe de Bibliografía del Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.supplier.field.vat_registration_number	Inscripción Estatal	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.database.record_moved	Registro movido para la {0}	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.receipt.renews	Renovaciones	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tabs.brief	Resumen Catalográfico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.vocabulary.datafield.685.subfield.i	Texto explicativo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.reinstall.confirm.question	Atención. Todas las opciones harán con que los datos de su biblioteca sean borrados a favor de los datos recuperados. Se recomienda hacer un backup antes de iniciar esta acción. ¿Desea continuar?	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.select.default	Seleccione una opción	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_095	Área de conocimiento de CNPq	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.button.new	Nuevo registro	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.029	ISNM	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.user_status.inactive	Inactivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.material_type.nonmusical_sound	Sonido no musical	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.022	ISSN	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.024	Otros números o códigos normalizados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.595.subfield.b	Notas de Bibliografía, índices y/o apéndices	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.595.subfield.a	Código de la bibliografía	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.020	ISBN	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.343.subfield.a	Método de codificación de la coordenada plana	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.343.subfield.b	Unidad de distancia plana	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.title.circulation.lending_receipt.printer.type	Tipo de impresora para recibo de préstamos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.111.subfield.n	Número de orden de evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	login.error.user_has_login	Este usuario ya posee un login	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.111.subfield.k	Subencabezamientos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.711.indicator.1.2	nombre en el orden directo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.close	Cerrar	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.711.indicator.1.1	nombre de la jurisdicción	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.111.subfield.e	Nombre de subunidades del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.711.indicator.1.0	nombre invertido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_041	Idioma	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.111.subfield.d	Fecha de realización del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.111.subfield.c	Lugar de realización del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.translations.error.invalid_file	Archivo inválido	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_043	Código geográfico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.import.save.failed	Falla al importar los Registros	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.success.update	Solicitud guardada con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.tab.record.custom.field_label.biblio_045	Código cronológico	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.111.subfield.g	Información adicional	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.upload_popup.title	Enviando Archivo	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.form	Formulario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	format.date	dd/MM/aaaa	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.111.subfield.a	Nombre del evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.user_type.page_help	<p>La rutina de Tipos de Usuarios permite el registro y búsqueda de los Tipos de Usuarios utilizados por la rutina de Registro de Usuarios. Aquí están definidas las informaciones como Límite de Préstamos simultáneos, plazos para devolución de préstamos y valores de multas diarias para cada tipo de usuario separadamente.</p>\n<p>Al accesar a esa rutina, el Biblivre listará automáticamente todos los Tipos de Usuarios previamente registrados. Usted podrá entonces filtrar esa lista, digitando el <em>Nombre</em> de un Tipo de Usuario que quiera encontrar.</p>	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.accesscards.success.unblock	Tarjeta desbloqueada con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.110	Autor - Entidad colectiva	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.013	Información de control de patentes	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.111	Autor - Evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.login	Login	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	multi_schema.configuration.title.general.subtitle	Subtítulo de este Grupo de Bibliotecas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.730	Entrada secundaria - Título uniforme	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.949	Sello Patrimonial	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	error.invalid_parameters	El Biblivre no fue capaz de entender los parámetros recibidos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.525.subfield.a	Nota de Suplemento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.indexing_groups.title	Título	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.success.save	Cotización incluida con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.items.administration_permissions	Administrar permisos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.title.late_lendings	Informe de Préstamos Atrasados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.configuration.description.general.backup_path	Esta configuración representa el camino, en el servidor donde el Biblivre está instalado, para la carpeta donde deberán guardarse las copias de seguridad del Biblivre. En caso que esta configuración este vacía, las copias de seguridad serán grabadas en el directorio <strong>Biblivre</strong> dentro de la carpeta del usuario del sistema.<br>Recomendamos que este camino esté asociado a algún tipo de backup automático en nube, como los servicios <strong>Dropbox</strong>, <strong>SkyDrive</strong> ou <strong>Google Drive</strong>. En caso que el Biblivre no consiga guardar los archivos en el camino especificado, los mismos serán guardados en un directorio temporario y podrán quedar indisponibles con el tiempo. Recuerde, un backup es la única forma de recuperar los datos incluidos en el Biblivre.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.request.field.author_type	Tipo de Autor	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.lending.lending_count	Ejemplares prestados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.permissions.confirm_delete_record_title.forever	Excluir Login de Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.holding.datafield.541	Nota sobre la fuente de adquisición	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.authorities.datafield.100	Autor - Nombre personal	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.title.user_creation_count	Total de Inclusiones Por Usuario	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.700	Entrada secundaria - Nombre personal	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.unblock	Desbloquear	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.maintenance.backup.error.invalid_schema	La lista de backup posee una o más bibliotecas inválidas	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	common.calculating	Calculando	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.material_type.all	Todos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.field.requisition	Solicitud	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.bibliographic.automatic_holding.holding_volume_count	Cantidad de volúmenes de la Obra	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	multi_schema.manage.error.create	Falla al crear nueva biblioteca.	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.710	Entrada secundaria - Entidad Coletiva	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.711	Entrada secundaria - Evento	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.vocabulary.confirm_delete_record.forever	Será excluido permanentemente del sistema y no podrá ser recuperado	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	acquisition.quotation.success.delete	Cotización excluida con éxito	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	marc.bibliographic.datafield.740.indicator.2._	ninguna información suministrada	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	administration.reports.field.lendings	Préstamos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	circulation.user_cards.selected_records_plural	{0} usuarios seleccionados	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.lending.error.limit_exceeded	El lector seleccionado excedió el límite de préstamos permitidos	2014-07-19 11:28:46.69376	1	2014-07-19 11:28:46.69376	1	f
es	cataloging.error.invalid_data	No fue posible procesar la operación. Por favor, intente nuevamente.	2014-07-19 11:35:18.227701	1	2014-07-19 11:35:18.227701	1	f
es	administration.permissions.login_data	Datos para el acceso al sistema	2014-07-19 11:35:18.227701	1	2014-07-19 11:35:18.227701	1	f
es	administration.reports.field.no_data	No existen datos para Generar este Informe	2014-07-19 11:35:18.227701	1	2014-07-19 11:35:18.227701	1	f
es	administration.reports.field.user_data	Datos	2014-07-19 11:35:18.227701	1	2014-07-19 11:35:18.227701	1	f
pt-BR	multi_schema.select_restore.description_found_backups	Abaixo estão os backups encontrados na pasta <strong>{0}</strong> do servidor Biblivre. Clique sobre o backup para ver a lista de opções de restauração disponíveis.	2014-07-19 13:48:01.039737	1	2014-07-19 13:48:01.039737	1	f
pt-BR	multi_schema.restore.dont_restore	Não restaurar esta biblioteca	2014-07-19 13:48:01.039737	1	2014-07-19 13:48:01.039737	1	f
pt-BR	multi_schema.restore.restore_complete_backup.title	Restaurar todas as informações do Backup, substituindo todas as bibliotecas deste Biblivre	2014-07-19 13:48:01.039737	1	2014-07-19 13:48:01.039737	1	f
pt-BR	multi_schema.select_restore.library_list_inside_backup	Bibliotecas neste backup	2014-07-19 13:48:01.039737	1	2014-07-19 13:48:01.039737	1	f
pt-BR	multi_schema.backup.schemas.title	Cópia de Segurança (Backup) de Múltiplas Bibliotecas	2014-07-19 13:50:48.346587	1	2014-07-19 13:50:48.346587	1	f
pt-BR	multi_schema.select_restore.title	Restauração de Backup de Múltiplas Bibliotecas	2014-07-19 13:50:48.346587	1	2014-07-19 13:50:48.346587	1	f
pt-BR	multi_schema.backup.schemas.description	Selecione abaixo todas as bibliotecas que farão parte do backup. Mesmo que um backup possua diversas bibliotecas, você poderá escolher quais deseja restaurar quando precisar.	2014-07-19 13:50:48.346587	1	2014-07-19 13:50:48.346587	1	f
pt-BR	multi_schema.restore.title	Opções de Restauração de Backup	2014-07-19 14:05:42.310014	1	2014-07-19 14:05:42.310014	1	f
pt-BR	multi_schema.restore.warning_overwrite	Atenção: já existe uma biblioteca cadastrada com o endereço acima. Se você fizer a restauração com esta opção selecionada, o conteúdo da biblioteca existente será substituído pelo conteúdo do Backup.	2014-07-19 13:48:01.039737	1	2014-07-19 14:05:42.310014	1	f
pt-BR	multi_schema.restore.restore_with_original_schema_name	Restaurar esta biblioteca usando seu endereço original	2014-07-19 13:48:01.039737	1	2014-07-19 14:05:42.310014	1	f
pt-BR	multi_schema.restore.restore_with_new_schema_name	Restaurar esta biblioteca usando um novo endereço	2014-07-19 13:48:01.039737	1	2014-07-19 14:05:42.310014	1	f
pt-BR	multi_schema.restore.restore_complete_backup.description	Caso você deseje restaurar todo o conteúdo deste backup, use o botão abaixo. Atenção: Isso substituirá TODO o conteúdo do seu Biblivre, inclusive substituindo todas as bibliotecas existentes pelas que estão no backup. Use esta opção apenas se desejar voltar completamente no tempo, até a data do backup.	2014-07-19 13:48:01.039737	1	2014-07-19 14:11:39.121566	1	f
pt-BR	multi_schema.restore.restore_partial_backup.title	Restaurar bibliotecas de acordo com os critérios acima	2014-07-19 13:48:01.039737	1	2014-07-19 14:11:39.121566	1	f
pt-BR	administration.maintenance.backup.error.no_schema_selected	Nenhuma biblioteca selecionada	2014-06-14 19:34:08.805257	1	2014-07-19 17:20:20.928313	1	f
pt-BR	administration.maintenance.backup.error.invalid_destination_schema	O atalho de destino é inválido	2014-07-19 17:20:20.928313	1	2014-07-19 17:20:20.928313	1	f
pt-BR	administration.maintenance.backup.error.backup_file_not_found	Arquivo de backup não encontrado	2014-07-19 17:20:20.928313	1	2014-07-19 17:20:20.928313	1	f
pt-BR	administration.maintenance.backup.error.invalid_origin_schema	O Backup não possui a biblioteca selecionada	2014-07-19 17:20:20.928313	1	2014-07-19 17:20:20.928313	1	f
pt-BR	administration.maintenance.backup.error.duplicated_destination_schema	Não é possível restaurar duas bibliotecas para um único atalho	2014-07-19 17:20:20.928313	1	2014-07-19 17:20:20.928313	1	f
en-US	cataloging.bibliographic.button.export_records	Export records	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.confirm_delete_record_title.forever	Delete supplier record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.circulation_user	User Registry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	text.main.noscript		2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.title.dewey	Dewey Classification Report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.administration_reports	Reports	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.digits	Significant digits	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.material_type.object_3d	Object 3D	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.error.invalid_data	It was not possible to process the operation. Please try again.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.button.cancel	Cancel	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.field.supplier	Supplier	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.022.subfield.a	ISSN number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.title.general.title	Library title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.013.subfield.e	Patent status	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.error.record_not_found	Record not found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.013.subfield.d	Date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.013.subfield.f	Part of a document	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.confirm_cancel_editing.2	Modifications will be lost	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.confirm_cancel_editing.1	Do you wish to cancel editing this acquisition order?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.256.subfield.a	Characteristics of the computer file	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.date_from	from	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.date	Date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.button_exclude_digital_media	Create backup without digital files	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.title.general.psql_path	Path for the program psql	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.cataloging	Cataloging	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.vocabulary_913	Local Code	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.013.subfield.a	Number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.013.subfield.b	Country	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.013.subfield.c	Type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.indicator.1.0	No character to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.indicator.1.1	1 character to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.indicator.1.2	2 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.upload_button	Send	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.indicator.1.7	7 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.title.search.distributed_search_limit	Limit of results for distributed searches	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.indicator.1.8	8 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.default	Select...	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.indicator.1.9	9 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.490.indicator.1	Policy for serial split	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.title.unit_value	Unit Value	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.users_who_have_login_access	List only users having a Biblivre access login	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.restore.title	Backup Restoring Options	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.indicator.1.3	3 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.indicator.1.4	4 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.indicator.1.5	5 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.field.email	Email	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.circulation_user_cards	Printing of User Cards	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.indicator.1.6	6 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.attachment.alias	Insert a name for this digital file	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.fieldset.title_info	Information on Work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.611.indicator.1.2	compound surname (obsolete)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.611.indicator.1.3	family name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.611.indicator.1.0	simple or compound name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.611.indicator.1.1	simple or compound surname	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.082	Dewey Decimal Classification	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.080	Universal Decimal Classification	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.title_last_backups	Last Backups	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.receipt.lendings	Loans	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.555.indicator.1.8	Do not generate constant in the exhibition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.marc_popup.title	Edit MARC Record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.access_control.arrival_time	Arrival time	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.record.success.update	Record successfully modified	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.fieldset.dewey	Dewey Classification	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.title.requisition	Requisition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.555.indicator.1.0	Remissive index	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.button.save	Save	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.indicator.1.0	Does not generate entry for the Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.indicator.1.1	Generates entry for the title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.button.save	Save	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.administration_z3950_delete	Delete z3950 server record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.fine_value	Fine value	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.095	Area of knowledge of the CNPq	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.error.no_users_found	No user found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.090	Call number - Location	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.confirm_delete_record_title	Delete quotation record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.access_control.card_unavailable	Card unavailable	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.simple_term_title	Fill in Card Code	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.error.invalid_restore_path	The configured directory for restoring backup files is not valid	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.title.general.pg_dump_path	Path for the program pg_dump	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.add_one_card	Register New Card	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.administration_z3950_save	Save server z3950 record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.confirm_move_record_description_plural	Do you really wish to move these {0} records?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.labels.button.select_item	Select item	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.isbn	ISBN	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.title.general.backup_path	Destination path for safety copies (backups)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_300	Physical description	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.confirm_cancel_editing.2	All the modifications will be lost	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.upload.button	Send language	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.340.subfield.e	Carrier	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.confirm_cancel_editing.1	Do you wish to cancel editing this user?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.success.block	Card successfully blocked	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.select_restore.description_found_backups	Below the backups found in the folder <strong>{0}</strong> of the Biblivre server. Click on backup to see the restoring list of options available.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.340.subfield.c	Materials applied to surface	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.340.subfield.d	Technique in which the information is recorded	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_306	Duration (time)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.340.subfield.a	Basis and configuration of material	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.340.subfield.b	Dimensions	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	error.invalid_method_call	Invalid method call	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.indicator.2._	no information provided	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.authorities_411	Another name format	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.authorities_410	Another name format	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.migration.groups.cataloging_bibliographic	Bibliographic and Units Catalogue	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.distributed.issn	ISSN (including hyphens)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.restore.warning_overwrite	Beware!:  There is already a library registered with the address above. If you restore using the option selected, the content of the existing library will be replaced by the Backup content.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	error.no_permission	You have no permission to execute this action	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.button.new	New user	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.confirm_delete_record.forever	He will be excluded from the system forever and cannot be retrieved	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.750.indicator.2	Thesaurus	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.750.indicator.1	Subject level	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.help_manual	Manual	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.field.id	Record Id	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.all_users	All-Users Report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.field.invoice_number	Invoice No.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.vocabulary.indexing_groups.te_term	Narrower Term (NT)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.610.subfield.x	General subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.610.subfield.y	Chronological subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.610.subfield.z	Geographical subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.450.subfield.a	Topical term not used	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.description_last_backups_1	Links for downloading the last backups made below. It is important to keep them in a safe place, as this is the only way to recover data, if necessary.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.description_last_backups_2	These files are kept in the directory specified in Biblivre configuration (<em>"Administration"</em>, <em>"Configurations"</em>, in the upper menu). Should this directory be unavailable for writing when the backup is made, a temporary directory will be used as an alternative. For that reason, some backups may not be available after a certain date. <span class="attention">we recommend downloading backups and keeping them in a safe place.</span>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.users.title	Search Reader	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.040.subfield.e	Convential sources of data description	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.040.subfield.d	Agency that modified the record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.700.indicator.1.3	family name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.040.subfield.c	Agency that transcribed the record in legible format by machine	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.040.subfield.b	Cataloging Language	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.040.subfield.a	Code of Cataloging Agency	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.700.indicator.1.0	simple or compound name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.700.indicator.1.1	simple or compound surname	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	error.invalid_json	Biblivre could not understand data received	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.700.indicator.1.2	compound surname (obsolete)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	aquisition.request.error.request_not_found	It was not possible to find the request	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.database	Base	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.description.4	Backup of just digital files is a copy of all the digital media files save in Biblivre, without any other data or information, such as users, catalographic basis, and so on.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.id_cpf	Taxpayer No.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.z3950.error.delete	Error in deleting Z39.50 Server	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.upload_popup.processing	Processing...	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.610.subfield.c	Venue of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.description.search.results_per_page	This configuration represents the highest number of results to be exhibited on a single page in the searches of the system. A very high number may lead to slow operating system.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.610.subfield.d	Date of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.610.subfield.a	Name of entity or of place	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.610.subfield.b	Subordinated units	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.password	Password	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.user_name	Name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.button_digital_media_only	Create digital files backup	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.610.subfield.n	Number of part - section of the work - order of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.user_status.active	Active	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.610.subfield.l	Text language	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.error.save	It was not possible to save the translations	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.610.subfield.k	Subheading. (amendments, protocols, selection, etc.)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.610.subfield.g	Additional information	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.authorities_400	Another name format	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.610.subfield.t	Title of the work close to entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.biblivre4restore.confirm_description	Do you really wish to restore this Backup?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.710.indicator.2	Type of secondary entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.confirm_move_record_title	Move records	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.710.indicator.1	Entry form	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.custom_count	Marc field counting report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.user_signup	Date of user signup	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.550.subfield.z	Geographical subdivision adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.550.subfield.x	General subdivision adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.550.subfield.y	Chronological subdivision adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.progress_popup.processing	Biblivre in this library is under maintenance. Please wait until maintenance is concluded.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.fieldset.dates	Period / Term	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.362.subfield.z	Information source	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.error.user_not_found	User not found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.migration.groups.users	Users, access Logins and Users Types	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.step_1_description	At this stage, you can import a file with records in MARC, XML and ISO2709 formats of conduct a search in other libraries. Select below the import arrangement you wish, selecting the file or filling in the search terms. The next step will be to select which records should be imported.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.vocabulary.confirm_delete_record_question	Do you really wish to delete this vocabulary record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	header.law	Law for the Promotion of Culture	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.printer_type.printer_24_columns	24 column printer	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.material_type.book	Book	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.database_count	Total Base Records in the Term	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.913.subfield.a	Local code	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.acquisition	Acquisition Date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.source_file_subtitle	Select a file with the records to be imported. This file´s format can be <strong>text</strong>, <strong>XML</strong> or <strong>ISO2709</strong>, provided original cataloging is compatible with MARC.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.confirm_delete_record_question.forever	Do you really wish to delete this user?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.670	Origin of information	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.title.general.default_language	Default language	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.description.general.default_language	This configuration represents the default language in the case of Biblivre exhibition.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.indicator.2	Number of characters to be overridden in alphabetation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.indicator.1	Generates secondary entry in sheet	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.error.java_locale_not_available	There no identifier of java language for the translations file	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.description.circulation.lending_receipt.printer.type	This configuration represent the type of printer to be used for printing loan receipts. Possible values are: 40 column printer, 80 column printer, or common printers (ink jet).	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.685	Historical or glossary note (GLOSS)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.indicator.2.0	Part of title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.z3950.field.port	Port	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.upload.field.upload_file	File	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.680	Scope note (SN)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.manage.new_schema.field.subtitle	Library subtitle	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.label.author_count	Number of records	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.indicator.2.5	Additional title in secondary cover sheet	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.indicator.2.6	Batch Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.indicator.2.7	Normal title*marc.bibliographic.datafield.246.indicator.2.8 = Spine title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.indicator.2.1	Parallel title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.loading	Loading	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.indicator.2.2	Specific title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.indicator.2.3	Another title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.indicator.2.4	Cover title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.step_2_description	In this case, please check the records to be imported and import them individually or altogether, through the buttons available at the end of the page. Biblivre automatically detects if the record is a bibliographic one, or authorities or vocabulary, but it allows the user to correct the importation beforehand. <strong>Important:</strong> Imported record will be added to the Work base and must be corrected and adjusted before moving them to the Main Base. This avoids incorrect records added directly to the final database.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.field.terms_of_payment	Payment terms	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_310	Periodicity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.450	UF (remissive for unused NT)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.reservation.reserve_failure	Work reservation failure	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.550.subfield.a	Topical term adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.summary	Catalogue Summary	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.option.dewey	Dewey Decimal Classification	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.040	Cataloging Source (NR)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.362.subfield.a	Information on Publishing Date and/or Volume	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.success.update	Supplier successfully saved	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.manage.button.show_log	Show log	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.change_password.current_password	Current password	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.830.subfield.v	Number of volume of sequence designation of the series	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.indicator.1.0	LC Classification	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.reservation.error.select_reader_first	To reserve a record you need, first of all, to select a reader	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.indicator.1.2	National Library of Medicine Classification	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.indicator.1.1	CDD	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.indicator.1.4	Steady location	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.indicator.1.3	Superintendent of Documents classification	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.indicator.1.6	Partly separated	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.operator.and_not	and not	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.indicator.1.5	Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.indicator.1.7	Specific classification	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.indicator.1.8	Another scheme	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.material_type.periodic	Periodical	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.830.subfield.a	Uniform title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.edition	Edition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_field.name	Name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.title.all_users	Users General Report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.949.subfield.a	Asset cataloging reference	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.dewey	CDD	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.field.author_numeration	Numeration after First Name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.isbn_already_in_database	There is already a record with that ISBN in the database	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.090.subfield.a	Classification	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.record.success.delete	Record successfully deleted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.090.subfield.b	Author code	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.090.subfield.c	Edition - volume	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.vocabulary_040	Cataloging source	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.090.subfield.d	Copy (unit) Number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.holdings_lent	Lent	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.description.search.result_limit	This configuration represents the maximum quantity of results to be found in catalographic searches. This limit is relevant to avoid slow Biblivre operations in libraries with a large number of records. Should the quantity of results of the search exceed the limit, the recommendation will be to improve search filters.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.555.indicator.1._	Index	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.record_imported_successfully	Record successfully imported	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.buttons.dismiss_fine	Dismiss fine	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.returned_lendings	Lendings returned	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.257.subfield.a	Country of producing entity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.back_to_search	Return to search	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.vocabulary_450	Use for Term	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	error.invalid_database		2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.button.edit_marc	Edit MARC	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.z3950.success.save	Z39.50 Server successfully saved	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.wait	Please wait	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.611.subfield.y	Chronological subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.611.subfield.x	General subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.indicator.1._	No information provided	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.611.subfield.z	Geographical subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.material_type.music	Music	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630	Subject - Uniform title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.z3950.success.delete	Z39.50 Server successfully deleted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.611.subfield.t	Title of the work close to entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.611.subfield.n	Order number of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.field.status	Status	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_362	Date of first publication	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	language_code	en-US	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.611.subfield.e	Name of event subunits	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.611.subfield.d	Date of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.611.subfield.c	Venue of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.670.subfield.b	Information found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.611.subfield.a	Name of event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.fine_popup.title	Late Return	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.670.subfield.a	Name taken from	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.receipt.lending_date	Loan date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.buttons.pay_fine	Pay	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.410.subfield.a	Name of the entity or of the place	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.migration.groups.cataloging_vocabulary	Vocabulary Catalogue	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.page_help	<p> The permissions routine allows the user to create a Login and Password, as well as the definition of the access permissions or use of the various Biblivre routines.</p>\n<p>The search will search Biblivre registered users and will work in the same manner of the User Registration Simple search routine.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.confirm_delete_record.trash	It will be moved to the recycle bin database	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.indexing_groups.all	Any field	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.651	Subject - Geographical name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.650	Subject - Topic	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.confirm_delete_record.forever	Card will be permanently deleted from system and cannot be recovered	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.backup.schemas.title	Backup copy of Multiple Libraries	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.help_faq	Frequently Asked Questions - FAQ	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.distributed.subject	Subject	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.711.indicator.1	Form of entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.success.save	Card successfully saved	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.acquisition_order	Orders	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_852	Public Notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.error.load	It was not possible to read the translations file	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.upload_popup.title	Sending File	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.error.no_request_found	It was not possible to find any requisition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.confirm_delete_record.forever	It will be permanently deleted from the system and cannot be retrieved	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.error.no_schema_selected	No library selected	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.cataloging_bibliographic_save	Save bibliographic record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.original_value	Original value	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.material_type.photo	Photograph	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.acquisition_supplier_delete	Delete supplier record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.z3950.confirm_delete_record_question.forever	Do you really wish to delete this Z39.50 Server?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.z	Standard note	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.q	Description of index in multimedia	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.p	Description of collection in multimedia	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.error.invalid_destination_schema	Invalid destination shortcut	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.o	Description of index in microfilm	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_830	Uniform Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.n	Description of collection microfilm	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.u	Description of index in other carriers	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.material_type.pamphlet	Pamphlet	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.t	Description of collection in other carriers	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.s	Description of index in Braille	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.r	Description of collection in Braille	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.i	Index description with online access	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.f	Library code at CCN	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.g	Description of index of printed collection	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.l	Description of collection in microfiche	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.m	Description of index in microfiche	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.j	Description of collection in CD-ROM	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.750.indicator.2	Thesaurus	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.issn	ISSN	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.k	Description of index CD-ROM	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.750.indicator.1	Subject level	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.search_authorities	Authorities	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.610	Subject - Collective Entity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.a	Library acronym	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.description.general.psql_path	Attention: This is an advanced configuration, but an important one. Biblivre will try to find automatically the path for the program <strong>psql</strong> and except in cases where an error is show down below, you will not need to modify this configuration. This configuration represents the path on the server where Biblivre is installed, for the executable <strong>psql</strong> which id distributed with the PostgreSQL. Should this configuration be invalid, Biblivre will not be able to create safety copies.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.611	Subject - Event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.d	Year of last acquisition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.e	Location	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.b	Description of printed collection	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947.subfield.c	Type of acquisition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.indicator.2.1	1 character to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.indicator.2.0	No character to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.access_control.card_in_use	Card in use	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.fieldset.field_count	Count by Marc field	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.041.subfield.b	Language code of summary or abstract	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.041.subfield.a	Language code of text	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.holding.confirm_delete_record_question	Do you really wish to delete this unit record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.reindex.button_bibliographic	Reindex bibliographic base	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.option.database.main	Main	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.600	Subject - Personal name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.field.status	Status	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.041.subfield.h	Language code of original document	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.045.indicator.1.0	Date - sole period	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.045.indicator.1.2	Date extension - periods	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.045.indicator.1.1	Date - multiple period	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.indexing_groups.subject	Subject	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.address_complement	Complement	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.cataloging_bibliographic_private_database_access	Access to Private Database.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.150.subfield.z	Geographical subdivision adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.150.subfield.y	Chronological subdivision adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.place	Local	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.150.subfield.x	General subdivision adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.isrc	ISRC	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.migration.groups.lendings	Active loans, loan and fine historical record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.150.subfield.a	Topical term adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.342.subfield.d	Longitude Scale	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.342.subfield.c	Latitude Scale	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.user_type.error.save	Error saving User Type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.migration.groups.acquisition	Acquisitions (Supplier, Requisition, Quotation and Order)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.status.any	Any	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.reservation.users.title	Search Reader	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.confirm_delete_record_question.forever	Do you really wish to delete this Card?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.select_restore.title	Backup restoring of Multiple Libraries	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.restore.restore_with_original_schema_name	Restore this library using the original address	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	field.error.invalid	This value is not valid for this field	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.150.subfield.i	Qualifier	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.342.subfield.a	Name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.342.subfield.b	Coordinate Unit or Distance Unit	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.administration_usertype_save	Save user type record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.access.user.search	Users	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.vocabulary.indexing_groups.all	Any field	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_876	Restricted access notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.change_status.question.unblock	Do you really wish to unblock this Card?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.100.indicator.1.3	family name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.material_type.movie	Film	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.100.indicator.1.1	simple or compound surname	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.migration.groups.cataloging_authorities	Authorities Catalogue	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.100.indicator.1.2	compound surname (obsolete)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.100.indicator.1.0	simple or compound name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.holdings	Unit Registry Report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.indicator.2.3	3 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.field.unit_value	Unit Value	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.110.indicator.1	Entry form	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.indicator.2.2	2 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.indicator.2.7	7 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.indicator.2.6	6 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.cancel	Cancel	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.indicator.2.5	5 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.indicator.2.4	4 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.administration_usertype_delete	Delete user type record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.indicator.2.9	9 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.indicator.2.8	8 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.open	Open	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.status.in_use	In use	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.save_as_new	Save as New	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	error.void		2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.author	Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.manage.error.cant_disable_last_library	Cannot disable all the libraries in this group. At least one should be enabled.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.670	Origin of information	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.field.info	Remarks	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.author	Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.status.cancelled	Cancelled	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.error.invalid_backup_type	This is an invalid backup type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.operator.or	or	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.110	Author - Collective entity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.111	Author - Event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.fieldset.author	Search by Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.subfield.b	Title complement	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.user_type.field.lending_limit	Limit for simultaneous loans	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	label.username	User	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.error.delete.user_has_lendings	This user has active lendings. Return items before deleting this user.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.subfield.a	Title/abbreviated title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.access_control.user_has_card	User already has a card	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.accesscards.select_card	Select Card	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.subfield.g	Miscellaneous	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.subfield.f	Information on volume /fascicle number and/or date of the work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.no_backups_found	No backup found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.warning	This process may take some minutes, depending on the hardware configuration of your server.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.subfield.i	Show text	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.subfield.h	Physical means	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.504.subfield.a	Bibliography notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.receipt.expected_return_date	Return date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.z3950.field.name	Name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.invalid_backup_path	Invalid path. This directory does not exist or Biblivre is not authorized to write.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.subfield.n	Number of the part / section of the work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.subfield.p	Name of the part / section of the work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.100	Author - Personal name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.new_value	New value valor	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.access_control.page_help	<p> The <strong>"Access Control "</strong> allows managing the entry and permanence of readers in the library facilities. Select the reader through a search by name or Enrollment Number and insert the number of an access card available to bind that card to the reader.</p>\n<p>When the reader is leaving, you will be able to unbind the card looking for its code </p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.700.indicator.2.2	analytical entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.field.title	Main Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.distributed.author	Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.indexing_groups.total	Total	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.marc_field	Marc field Value	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.indicator.2	Number of characters to be overridden in alphabetation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.material_type.computer_legible	Computer file	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.indicator.1	Generates secondary entry in the sheet	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.usertype.confirm_delete_record.forever	User Type will be permanently deleted from system and cannot be restored	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.upload.title	Send language file	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.administration_datamigration	Import Biblivre 3 data	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130	Anonymous work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.error.save	Error when saving Card	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.address	Address	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.distributed.page_help	<p> Distributed searches allow retrieving information on records in contents from other libraries, which make their records available for collaborative searches and cataloging.</p>\n<p>In order to conduct a search please fill in the terms of the search, selecting your field of interest. Right afterwards, select one or more libraries where the records can be traced.. <span class="warn">Attention: select just a few libraries in order to prevent the Distributed Search from running too slowly, as this depends on the communication between libraries and on the size of each collection.</span></p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.save	Save	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.printer_type.printer_common	Common printer	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.number_of_titles	Number of Titles	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.button.continue_to_biblivre	Go to Biblivre	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.user_count_by_type	Total by User Types	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.login_data	Data for accessing the system	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.step_2_title	Select records for importation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.employee	Employee	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.current_value	Current value	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.uncancel	Restore	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.biblivre4restore.title_found_backups	Backups Found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.record.error.delete	Error deleting Record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.confirm_cancel_editing_title	Cancel editing of order record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permission.error.delete	Login deletion error	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.user_status.blocked	Blocked	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.biblivre4restore.success.description	Backup successfully restored	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.start_date	Starting Date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.680.subfield.a	Scope note	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.button.return	Return	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.confirm_cancel_editing_title	Cancel user editing	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.095.subfield.a	Subject areas	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.vocabulary.confirm_cancel_editing.2	All the modifications will be lost	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.vocabulary.confirm_cancel_editing.1	Do you wish to cancel editing this vocabulary record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.import_as	Import as:	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.cataloging_authorities_save	Save authority record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.confirm_delete_record.forever	Record will be deleted forever and cannot be recovered	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.material_type.thesis	Thesis	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.import_popup.importing	Importing records, please wait	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.fieldset.title.values	Values	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.150	NT	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.acquisition_request	Requests	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.750.indicator.1.0	No specified level	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.750.indicator.1.1	Primary subject	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.750.indicator.1.2	Secondary subject	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.download.description	Select below the language you wish to download.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.field.zip_code	ZIP Code	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.button.delete	Delete	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.migration.groups.z3950_servers	Z39.50 Servers	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.lending_date	Lending date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.field.info	Remarks	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.field.trademark	Fancy Name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.remove_item_button	Remove	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.manage.new_schema.title	Creation of New Library	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.045.indicator.1._	Subfields |b or |c are not present	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.other_name	Other name format	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	aquisition.supplier.error.supplier_not_found	It was not possible to find the supplier	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_cards.button.print_user_cards	Print user cards	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.vocabulary.indexing_groups.tg_term	Broader Term (BT)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.change_password.description.6	If the user losses his/her password, he / she must contact the Administrator or the Librarian in charge of Biblivre, and they may furnish a new password.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.issn_already_in_database	There is already a record with this ISSN in the database	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.subfield.a	Uniform title given to the document	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.z3950.field.url	URL	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.550.subfield.y	Chronological subdivision adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.error.delete	Error when deleting Card	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.550.subfield.z	Geographical subdivision adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.subfield.d	Date that appears close to the uniform entry title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.address_zip	ZI P Code	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.subfield.l	Text language. Text language in full	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.subfield.k	Subheadings	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.subfield.f	Date of edition of the item that is being processed	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.button.show_log	Show log	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.subfield.g	Additional information	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.913.subfield.a	Local code	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.receipt.return_date	Return date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.change_password.description.1	Password change means the process in which the user may modify current password with a new one. For security reasons, we suggest users to do this periodically.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.record.error.move	Error moving Records	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.administration_datamigration	Data Migration	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.change_password.description.3	Use letter, special characters and numbers if your password	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.change_password.description.2	A three-digit password is the only rule to create passwords in Biblivre. However, we suggest following these guidelines:	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.subfield.p	Name of part - Section of the work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.page_help	<p>Record import allows expanding your database without any need of manual cataloging. New records can be imported through Z39.50 searches or from files exported by other librarianship systems.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.change_password.description.5	Use a larger number of digits than recommended.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.change_password.description.4	Use Capital and small letters; and	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.550.subfield.a	Topical term adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.subfield.y	Chronological subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.subfield.z	Geographical subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.subfield.x	General subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.750.subfield.z	Geographical subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.750.subfield.y	Chronological subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.750.subfield.x	General subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.block	Block	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.949.subfield.a	Asset cataloging reference	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.750.subfield.a	Topical term adopted by Thesaurus	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.410.subfield.a	Name of entity or name of place	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.550.subfield.x	General subdivision adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.renew_success	Loan renewed successfully	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.cataloging_vocabulary	Vocabulary	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.labels.never_printed	List only the copies that never had printed labels	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.user_total_lending_list	Background information on loans to this reader	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.material_type.manuscript	Manuscript	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.operator.and	and	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.step	Step	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.cataloging_authorities_delete	Delete authority record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.change_status.question.cancel	Do you really wish to cancel this Card?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.reinstall.title	Restoration and Reconfiguration	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.button.cancel	Cancel	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.success.generate	Report successfully generated. It will open on another page.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.labels.selected_records_singular	{0} unit (copy/item) selected	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.502.subfield.a	Dissertation or thesis notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.auto_download	Backup made, automatic download in a few seconds…	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.groups.acquisition	Acquisition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.database.record_deleted	Record deleted for ever	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.040.subfield.c	Agency that transcribed the record in legible format per machine	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.040.subfield.b	Cataloging language	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.040.subfield.e	Conventional sources for data description	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.040.subfield.d	Agency that modified the record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.040.subfield.a	Code of cataloging agency	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.title.searches_by_date	Report on the Total Number of Searches by Period	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	error.runtime_error	Unexpected error during runtime	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.field.subtitle	Parallel titles/subtitle	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.cancel.description	Press the button below to desist restoring this bb4 installation and return to your library.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.success.save	Supplier successfully included	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.045.indicator.1	Type of chronological period	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.administration_backup	Obtain a backup of the database	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.form.hidden_subfields_plural	Show {0} hidden subfields	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.reservation.page_help	<p>To make a reservation you will need to select the reader in the name of whom the reservation is made and, right afterwards, you will have to select the record to be reserved. Search by reader can be made  by name, user number or other field previously registered. In order to find registration, you have to carry out a search similar to the bibliographic search.</p>\n<p>Cancellations can be made selecting the reader with the reservation.</p><p>The duration of the reserve is calculated according to the User Type, configured by the <strong>Administration</strong> menu and defined during the reader´s registration.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.users_with_pending_fines	List only users with pending fines	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.confirm_delete_record_title	Delete supplier record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.acquisition	Acquisition Order Report for the Period	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.button.search	Search	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.confirm_delete_record.forever	User Login and permissions will be deleted forever from the system and cannot be restored.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.return_success	Unit returned successfully	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.search_count	{current} / {total}	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.description.administration.z3950.server.active	This configuration is showing whether local server z39.50 will be active. In case of multiple libraries, the name of the Server z39.50 Collection will be identical to the name of each library. For example, the name of the collection for this installation is "{0}".	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.printer_type.printer_80_columns	80-column printer	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configurations.error.invalid	The value specified for one of the configurations is invalid	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.search_z3950	Distributed	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.400	Another name format	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.user.name_or_id	Name or User Number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.error.start_less_than_or_equals_end	Initial number must be less or equal to end number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.users.success.update	User successfully saved	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.user.field	Field	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.title	Safety Copy (Backup)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.error.invalid_marc	Error reading Record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.vocabulary.confirm_cancel_editing_title	Cancel editing of vocabulary record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.no_fines	This user has no fines	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.410	Another name format	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.button.generate_report	Generate Report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.110.subfield.d	Date of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.110.subfield.c	Venue for the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.110.subfield.b	Subordinated units	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.holding.confirm_cancel_editing.2	All the modifications will be lost	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.accession_number	Asset Number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.holding.confirm_cancel_editing.1	Do you wish to cancel editing this unit record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.accesscards.return.success	Card successfully returned	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.title	Records Importation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.110.subfield.l	Text language	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.in_this_library	In this library	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.110.subfield.n	Number of the part of the section of the work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.indicator.2.0	Not numbered	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.usertype.confirm_delete_record_question.forever	Do you really wish to delete this User Type?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.users.success.delete	User deleted forever	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	label.logout	Logout	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.field.quotation	Quotation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.field.requisition_select	Select a Requisition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.title.holdings	Asset Cataloging Report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	warning.create_backup	You have not created a backup copy in more than 3 days	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.manage.new_schema.field.schema	Library shortcut	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.user.remove_item_button	Remove	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.110.subfield.a	Name of entity or place	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.user_status	Status	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.580	Linkage Note	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.740.subfield.a	Additional title - analytical title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.indicator.1.1	Generate note and secondary title entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.indicator.1.0	Generate note, do not generate secondary title entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.usertype.confirm_delete_record_title.forever	Delete User Type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.acquisition_quotation_delete	Delete quotation record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.switch_to	Switch to	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.indicator.1.3	Do not generate note, generate secondary title entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.indicator.1.2	Do not generate note nor secondary title entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.error.psql_not_found	PSQL not found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.common.digital_files	Digital Files	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.740.subfield.n	Number of part - section of the work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.dewey	Dewey Classification Statistic	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.740.subfield.p	Name of part - section of the work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.confirm_delete_record.trash	It will be moved to the trash database	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.labels.page_help	<p>The module <strong>"Label Printing "</strong> allows creating internal and spine (back) identifications for the book in the case of library copies.</p>\n<p>Labels for one or more titles can be created in a single printing, using the search below. Please remember the details, as the result of this search is a list of copies (units) and not of bibliographic records.</p>\n<p> After finding the copy(ies) you are interested in, use the button <strong>"Select copy (or unit) "</strong> to add it to the list of labels to be printed. You may carry out several searches, without losing the previous selection. When you are finally satisfied with the selection, press the button <strong>"Print labels "</strong>. You may choose which model of the labels page you will use and the initial position.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.024.indicator.1.2	International Standard Music Number (ISMN)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.024.indicator.1.0	International Standard Recording Code (ISRC)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.receipt.accession_number	Asset reference number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.access_control.user_has_no_card	No card is associated to this user	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.date_to	to	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.deleted	Deleted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.in_these_libraries	In these libraries	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.configuration.title.general.title	Name of this Group of Libraries	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.field.author	Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.cataloging_import	Record Importation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.590	Local notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.yes	Yes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.595	Notes for inclusion in bibliographies	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.download.title	Download language file	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.button.import_this_record	Import this record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.status.in_use_and_blocked	In use and blocked	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.error.backup_file_not_found	Backup file not found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.lendings_late	Total number of late books	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.confirm_delete_record_question	Do you really wish to delete this supplier record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.button.select_item	Select	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.450.subfield.a	Topical term not used	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.users.error.save	Failure fixing User	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.342.indicator.2	Geo-spatial reference dimensions	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.580.subfield.a	Linkage note	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.342.indicator.1	Geo-spatial reference dimensions	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.user_returned_lendings	Returns Record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.administration_z3950_search	List z3950 Servers	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	login.password.success	Password successfully modified	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.830.indicator.2.9	9 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.830.indicator.2.8	8 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	label.password	Password	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_cards.button.select_item	Select user	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.confirm_delete_record.forever	It will be deleted from the system forever and cannot be restored	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.select_marc_field	Select a Marc field	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.simple_search	Simplified Bibliographic Search	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.receipt.holding_id	Record No.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.830.indicator.2.2	2 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.form.repeat	Repeat	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.830.indicator.2.3	3 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.830.indicator.2.0	No character to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.830.indicator.2.1	1 character to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.830.indicator.2.6	6 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.confirm_cancel_editing_title	Cancel edition of bibliographic record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.830.indicator.2.7	7 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.830.indicator.2.4	4 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.830.indicator.2.5	5 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.750.subfield.a	Topical term adopted by Thesaurus	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.title.topographic	Topographic Report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.user_status.pending_issues	Pending issues	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.error.no_records_found	No records found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.receipt.returns	Returns	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.today	Today	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.lendings	Report on Loans during Period	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.vocabulary_360	Associated term	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	error.form_invalid_values	Errors were found in the filling in of the form below	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.user	Report by User	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	field.error.max_length	This field must have {0} characters maximum	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.110.indicator.1	Entry form	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.555	Note of Cumulative or Remissive Index	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.isbn	ISBN	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.status.blocked	Blocked	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.inactive_users_only	List solely inactive users	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.reinstall.button	Go to the reinstall and reconfiguration screen	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configurations.page_help	<p>The Configurations routine allows configurations in several parameters used by Biblivre, for example Library Title, Default Language or Currency to be used. Each configuration has an explanatory text in order to facilitate usage.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.title.lendings_by_date	Report on Loans by Period	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.last_backup	Last Backup	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.edit	Edit	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.550	BT (broader term)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.restore.dont_restore	Do not restore this library	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_243	Collective Uniform Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.delete	Delete	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.indicator.2.2	Alternate numbering	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.360	Remissive VT (see also) and AT (related or associated term)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	warning.change_password	You have not changed the standard administrator password yet	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.total	Total	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_240	Uniform Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.indicator.2.1	Primary numbering	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.525	Supplementary Note	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.button.print_return_receipt	Print return receipt	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_cards.popup.description	Select in which label you wish to start printing	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.error.delete	Error when deleting Requisition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.521	Target public notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.administration_accesscards_list	List access cards	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.024.indicator.1	Number type or standardized code	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_245	Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.520	Summary notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.250.subfield.b	Additional information	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.user_type.error.type_has_users	This User Type has Users registered	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.250.subfield.a	Indication on the edition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.user_type.error.delete	Error when deleting User Type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.210.indicator.2._	Key abbreviated Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.add_multiple_cards	Register Card Sequence	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.page_help	<p>The bibliographic search allows retrieving information on the records of this library, listing the volumes, catalographic fields and digital files.</p>\n<p>The simplest way is using the <strong>Simple search </strong>, that will search each one of the terms typed in the following fields: <em>{0}</em>.</p>\n<p>Terms are sought in its full form, however it is possible to use the asterisk (*) to look for incomplete terms, so that the serarch in <em>'brasil*'</em> may find, for example, records containing <em>'brasil'</em>, <em>'brasilia'</em> and in <em>'brasileiro'</em>. Double quotation marks can be used to find terms in sequence, so that search  <em>"my love"</em> may find records containing the two terms together, but shall not find records such as  in the text <em>'my first love'</em>.</p>\n<p>The <strong>advanced search</strong> provides a higher control on the records traced, allowing, for example, searches by cataloging date or exactly in the desired field.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.error.invalid_photo_extension	The extension of the filed selected is not valid for the photo of the user. Use fields such as.png, .jpg, .jpeg or .gif	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.541.indicator.1._	no information provided	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.database.private_full	Private Base	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.534	Fac-simile notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.creation_date	Date of Inclusion	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.530	Notes on availability of physical form	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.750	Topical term	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.indicator.2._	No information provided	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.vocabulary.page_help	<p> Vocabulary searches can retrieve information on the terms in the coolection of this library, if and when they are cataloged.</p>\n<p>Search will look for each one of the terms typed in the following fields: <em>{0}</em>.</p>\n<p> Terms are sought in its full form, however it is possible to use the asterisk (*) to look for incomplete terms, so that the search in <em>'brasil*'</em> may find records containing, for example, <em>'brasil'</em>, <em>'brasilia'</em> and in <em>'brasileiro'</em>. Double quotation marks can be used to find terms in sequence, so that search  <em>"my love"</em> may find records containing the two terms together, but shall not find records such as  in the text <em>'my first love'</em>.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.show_all	Show all the {0} backups	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.field.response_date	Quotation arrival date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.title.bibliography	Bibliography Report by Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.field.author_title	Title and other terms associated to name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_260	Printer	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.simple_search	Simple Search	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.cataloging_bibliographic_delete	Delete bibliographic record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permission.success.delete	Login successfully deleted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.500	Notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.502	Notes of dissertation or thesis	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.504	Bibliography Notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.505	Content notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.541.indicator.1.1	non confidential	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.541.indicator.1.0	confidential	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.buttons.apply_fine	Fine	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lendings.holding_list_lendings	List only copies lent	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.administration_password	Change Password	2014-07-26 10:56:18.338867	1	2014-07-26 13:42:51.201768	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_250	Edition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.restore.restore_complete_backup.description	Should you wish to restore all the contente in this backup, use the button below. Beware! This will replace ALL the content of your Biblivre, also replacing all the existing libraries for those in the backup. Use this option only if you wish to go back in time, until backup date.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.datafield	MARC field	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_255	Scale	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_256	File characteristics	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_257	Production place	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.success.update	Quotation successfully saved	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_258	Information on the material	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.location	Location	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_field.photo	Photograph	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	login.error.empty_login	The field login cannot be empty	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.515	Numeration Peculiarity Note	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.selected_records_plural	{0} records selected	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.clear_search	Clear search terms	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.biblio	Bibliographic	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.backup_not_complete	Backup not complete	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.error.no_supplier_found	It was not possible to find a supplier	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.confirm_cancel_editing_title	Cancel quotation record editing	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.users.success.disable	Success in marking user as inactive	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	digitalmedia.error.file_not_found	The specified file was not found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.error.delete	Error when deleting quotation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	warning.fix_now	Solve this problem	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.holding.availability.available	Available	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.confirm_delete_record_title	Delete bibliographic record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.holding.availability	Availability	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.status.available	Available	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.address_city	City	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	login.error.empty_new_password	The field "new password" cannot be empty	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.return_date	Return date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.subfield.c	Indication on responsibility for the work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.subfield.a	Main Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.cataloging_vocabulary_move	Move Vocabulary record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.subfield.b	Parallel Titles /subtitles	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.biblivre4restore.confirm_title	Restore Backup	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.receipt.author	Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.labels.popup.description	Select in which label you wish to start printing	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.reservation.button.delete	Delete	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.subfield.p	Name of part - section of the work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.email	Email	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.field.country	Country	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.subfield.n	Number of part - section of the work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.111.indicator.1.0	Inverted name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.multi_schema_configurations	Configurations	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.111.indicator.1.1	Name of jurisdiction	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.subfield.h	Means	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.111.indicator.1.2	Name in the direct order	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.cataloging_bibliographic_move	Move bibliographic record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.type.biblio	Bibliographic record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.change_status.cancel	Card will be canceled and will not be available for use	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_status.blocked	Blocked	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.order	Sort by	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configurations.error.file_not_found	File not found.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.source_search_title	Import records from a Z39.50 search	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.reservation.expiration_date	Reservation expiration date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.field.state	State	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.title.general.subtitle	Library subtitle	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.upload_popup.uploading	Sending file...	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.error.save	Supplier saving error	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.670.subfield.a	Note on origin of the term	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.upload_popup.title	Opening File	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.database.main_full	Main Base	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.page_help	<p>Order routine allows order registration and research (purchases) with registered suppliers. To register a new order, a previously registered Supplier and a Quotation must be chosen, in addition to providing information such as Validation Date and Invoice information.</p>\n<p> Each search will look for each of the terms entered in the fields<em>Number of Order Registration, Fancy Name of Supplier and Author or Title of Request</em>.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.555.subfield.3	Specified materials	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.title.general.multi_schema	Set up Multi-libraries	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.error.couldnt_restore_backup	The selected backup could not be restored	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.administration_configurations	Manage configurations	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.holdings_available	Available	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.group.custom	Customized Report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.acquisition_request_save	Save requests record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.accesscards.return.error	Card return error	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.fine.failure_pay_fine	Fine payment failure	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.indicator.2.2	analytical entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.circulation_access	Access Control	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.login_change_password	Change password	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.210	Abbreviated Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.multi_schema_manage	Libraries Management	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.856.subfield.y	Text link	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	field.error.date	The Value filled in is not a valid date. Use the format {0}	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.856.subfield.u	URI	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.accesscards.lend.error	Binding Card Error	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_field.login	Login	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.856.subfield.d	Path	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.upload_popup.processing	Processing...	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.no_data	No data available for creating this report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.555.subfield.a	Cumulative and remissive index note	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.manage.new_schema.field.title	Library name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.555.subfield.b	Source available	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_status.active	Active	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.z3950.success.update	Z39.50 Server successfully updated	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.856.subfield.f	File name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.555.subfield.c	Degree of control	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.555.subfield.d	Bibliographical reference	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.reserved.warning	All the copies (units) available of this record are reserved for other readers. Loans can be made, however, please see the reservation information.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.321.subfield.b	Dates of previous periodicity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.phone_cel	Mobile phone No.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.321.subfield.a	Previous periodicity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.type.authorities	Authorities	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.555.subfield.u	Resource uniform identifier	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.manage.new_schema.button.create	Create Library	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.searches	Report on Total Searches during Period	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.open_item_button	Open record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.administration_configurations	Configurations	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.041.indicator.1.0	Item is not and does not include translation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.tabs.reservations	Reservations	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.cancel	Cancel	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	field.error.min_length	This field must have {0} characters minimum	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.041.indicator.1.1	Item is or incluldes translation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.distributed.isbn	ISBN	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.cataloging_labels	Label Printing	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.option.title	Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.publication_year	Year of publication	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.circulation_save	Save user record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.field.info	Remarks	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.no_attachments	This record does not have digital files	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.750.subfield.z	Geographical subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.error.save	Error when saving Requisition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.750.subfield.x	General subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.505.subfield.a	Content notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.750.subfield.y	Chronological subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.holding.confirm_delete_record_title	Delete unit record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.button.print_lending_receipt	Print lending receipt	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.field.quotation_date	Quotation requisition date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.100.indicator.1	Entry form	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.lending.error.holding_is_lent	The item selected is already on loan	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.lendings_top	Top lending books	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.field.address_number	Number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.field.id	Registration order	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.250	Edition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.255	Cartographical Mathematical Datum	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.256	Characteristics of computer file	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.750.indicator.2.0	Library of Congress Subject Heading	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.obs	Remarks	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.help	Help	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.258	Information about philatelic material	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.257	Country of producing entity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.material_type.articles	Article	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.restore.restore_partial_backup.title	Restore libraries in accordance with the criteria above	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.user_not_found	User not found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.150.subfield.y	Chronological subdivision adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.150.subfield.x	General subdivision adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.750.indicator.2.4	Source not specified	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.title.unit_value	Unit Value	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.lending.error.holding_unavailable	The item selected is not available for loans	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.150.subfield.z	Geographical subdivision adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.indexing_groups.author	Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.button_full	Create complete  backup	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.accession_number.full	Full Report of Asset Cataloging Reference	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.start_number	Start number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240	Uniform Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243	Agreed Title for Filing Purposes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245	Title principal	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.database_work	Work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246	Variant Form of Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.user_lendings	Active loans	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.page_help	<p>Quotation routine allows quotation registration search conducted with registered suppliers. To register a new Quotation, you must select a Supplier and a previously registered Acquisition; data such as value and quantity of works quoted are should also be included.</p>\n<p>Search will look for every single term inserted in fields <em>Quotation Registration Number or Supplier Fancy Name </em>.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.accesscards.bind_card	Associate (bind) Card	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.description.search.distributed_search_limit	This configuration represents the maximum number of results to be found on a research already distributed.  The use of a very high limit should be avoided, because searches distributed would take a long time in providing the results of the search.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.confirm_delete_record_question.forever	Do you really wish to delete this supplier record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.success.update	Card successfully saved	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.856.subfield.u	URI	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	text.multi_schema.select_library	List of Libraries	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.856.subfield.y	Link in text	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.printer_type.printer_40_columns	40-column printer	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.no_backups_found	No backups found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.856.subfield.d	Path	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.circulation_delete	Delete user record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.515.subfield.a	Numeration Peculiarity Note	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.856.subfield.f	File name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.user_type.field.name	User Type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.949	Asset cataloging reference	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.947	Information on the Collection	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.611.indicator.1	Form of entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.title.author	Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.indicator.1.8	8 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.title	Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.indicator.1.9	9 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.field.delivery_time	Delivery time (Promised on)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.description.general.currency	This configuration represents the currency to be used in the case of fines and on the acquisition module.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.restore.restore_complete_backup.title	Restore all the Backup information, replacing all the libraries in this Biblivre	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.database_main	Main	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.record.success.move	Records successfully moved	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.acquisition_quotation	Quotations	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.groups.circulation	Circulation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.150.subfield.a	Topical term adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.button.move_records	Move Records	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.holding.accession_number	Asset cataloging reference	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.150.subfield.i	Qualifier	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.payment_date	Payment date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_field.status	Situation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.error.no_valid_terms	The specified search does not contain valid terms	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.circulation_print_user_cards	Print user cards	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.users_with_late_lendings	List only users with pending lendings	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.field.delivered_quantity	Quantity received	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.title.holdings_full	Full Report on Asset Cataloging	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.page_help	<p>In order to conduct a loan you will have to select the reader who will take the volume and select the unit or copy to be lent. Search by reader can be made by name, user number or any other field previously registered. In order to find the copy, use your Asset Cataloging Reference.</p><p>Returns can be made through the selected reader or directly by the Asset Cataloging Reference of the copy (unit) which is being returned or renewed..</p><p>the deadline for returning the unit is calculated according to User Type, as configured by the menu <strong>Administration</strong> and defined during the reader registration process.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.user_type.field.fine_value	Value of fine in case of late returns	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.distributed_search	Distributed search	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.cataloging_authorities	Authorities	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.acquisition_quotation_list	List quotations	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.manage.disable	Disable library	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_cards.paper_description	{paper_size} {count} labels ({height} mm x {width} mm)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.fieldset.order	Order	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.selected_records_plural	{0} Values Added	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.670.subfield.b	Information found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.670.subfield.a	Name taken from	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.700.indicator.2	Type of secondary entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.700.indicator.1	Form of entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_field.short_type	Type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.indicator.1.2	2 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.indicator.1.3	3 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.indicator.1.0	No character to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.indicator.1.1	1 character to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.indicator.1.6	6 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.indicator.1.7	7 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.indicator.1.4	4 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.indicator.1.5	5 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.holding.availability.unavailable	Unavailable	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.group.circulation	Circulation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.holding.availability	Availability	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.reservation.delete_success	Reservation deleted successfully	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.029.subfield.a	ISNM number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.created_between	Cataloged between	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.confirm_delete_record_title.forever	Delete quotation record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.260	Publication, edition, etc.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.confirm_delete_record_question.forever	Do you really wish to delete this Order record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.fieldset.title.values	Values	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.confirm_delete_record.forever	It will be permanently deleted from the system and cannot be retrieved	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.913	Local code	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.simple_term_title	Fill in the search terms	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.reindex.title	Database reindexing	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.lending.error.blocked_user	The selected reader is blocked	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.records_found_singular	{0} record found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.710.indicator.2._	no information provided	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.error.delete	Error when deleting supplier	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.type.do_not_import	Do not import	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.indicator.1	Number of characters to be overridden in alphabetation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.indicator.2	Type of secondary entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.error.delete.user_has_accesscard	This user has an access card in use. Return the card before deleting this user.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.111.indicator.1	Entry form	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.field.created_by	Person in charge	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_130	Anonymous work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	language_name	English (United States)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_534	Facsimile notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.360.subfield.z	Geographical subdivision adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.360.subfield.y	Chronological subdivision adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.confirm_delete_record_title	Delete Order record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.360.subfield.x	General subdivision adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.upload_popup.uploading	Sending file...	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.reservations	Reservations Report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.reservation_date	Reservation Date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.vocabulary.term.up	Term Use for (UF)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_520	Summary notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.411.subfield.a	Name of event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_521	Target public notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.title.quantity	Quantity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.multi_schema	Multi-libraries	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_110	Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.tabs.form	Registry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_111	Author Event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.100.indicator.1.1	Single or compound Surname	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.100.indicator.1.2	Compound surname (obsolete)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.100.indicator.1.3	Family name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.configurations.page_help	The routine for Multi-libraries Configuration allows modification of global configurations of the library group and standard configurations to be used by the registered libraries. All the configurations marked with asterisk (*) will be used as standards in new libraries registered in this group, but they can be modified internally by administrators, through the option <em>"Administration"</em>, <em>"Configurations"</em>, in the upper menu.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.clear	Clear	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.100.indicator.1.0	Single or compound name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.selected_records_singular	{0} Value Added	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.vocabulary.term.tg	Broader Term (BT)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.vocabulary.term.te	Narrower Term (NT)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.preview	Pre-visualization	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.vocabulary.confirm_delete_record_title	Exclude vocabulary record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.490	Serial Indication	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.vocabulary.term.ta	Associated Term (AT)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.search	Search	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.modified	Updated on	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.521.subfield.a	Target public notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.phone_home	Home Telephone No.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.unclassified	<Unclassified>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.administration_translations	Manage translations	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.501.subfield.a	Notes starting with the term "with"	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.600.indicator.1	Entry form	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.260.subfield.b	Name of Publisher, Publishing company, etc..	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.260.subfield.c	Date of publication, distribution, etc.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.user.search	Insert name or User number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.260.subfield.e	Name of printing company	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.error.invalid_search_parameters	Parameters in this search are not correct	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.author_type.select_author_type	Select author type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.title.search.results_per_page	Results per page	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.260.subfield.a	Place of publication, distribution, etc.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	error.biblivre_is_locked_please_wait	This Biblivre is under maintenance. Please try again in a few minutes.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_500	Notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.confirm_delete_record.trash	Records will be sent to the trash database	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.260.subfield.f	Additional information	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_502	Thesis note	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.260.subfield.g	Date of print	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_505	Content notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_504	Bibliography notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_506	Restricted access notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.circulation_lending_list	List loans	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.520.subfield.a	Summary notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.reservation.record_reserved_to_the_following_readers	This record is reserved to the following readers	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.change_password.new_password	New password	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.110.subfield.b	Subordinated units	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.110.subfield.c	Venue of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.110.subfield.d	Date of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.subject	Subject	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configurations.save.success	Configurations modified successfully	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	z3950.adresses.list.no_address_found	Z39.50 Server found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	login.error.password_not_matching	The fields  "new password " and "repeat new password" have to be identical	2014-07-26 10:56:18.338867	1	2014-07-26 13:41:48.22945	1	f
en-US	marc.bibliographic.datafield.110.subfield.l	Text language	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.search_limit	The search conducted found {0} records, but only the {1} ones will be shown	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.110.subfield.n	Number of the part - section of the work - order of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.error.generate	Error when generating report. Check form information.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.button.renew	Renew	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.record.error.save	Error saving Record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_100	Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.user.open_item_button	Open record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.users.success.unblock	User successfully unblocked	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.vocabulary.simple_search	Vocabulary search	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.110.subfield.a	Name of entity or of place	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.error.unblock	Error when unblocking Card	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.acquisition_order_delete	Delete order records	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.confirm_cancel_editing.2	All the modifications will be lost	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.ok	Ok	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.confirm_cancel_editing.1	Do you wish to cancel editing this requisition record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.biblivre4restore.button	Restore selected backup	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.vocabulary.indexing_groups.total	Total	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.authorities_670	Name withdrawn from	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.z3950.confirm_cancel_editing_title	Cancel edition of Z39.50 Server	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.field_count	Field Count	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.362.indicator.1.1	Non-formatted note	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.error.invalid_file	Invalid File	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.362.indicator.1.0	Formatted style	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.no	No	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.search_button	Search	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.z3950.confirm_cancel_editing.2	All the modifications will be lost	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.z3950.confirm_cancel_editing.1	Do you wish to cancel editing the Z39.50 Server?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.biblivre4restore.success	Backup restoration	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.circulation_access_control_bind	Manage access control	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.confirm_cancel_editing.1	Do you wish to delete editing this supplier record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.cataloging_print_labels	Print labels	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.080.subfield.2	Number of edition of the CDU	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.610.indicator.1.0	simple or compound name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.confirm_cancel_editing.2	All the alterations will be lost	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.610.indicator.1.3	family name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_cards.popup.title	Label format	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.610.indicator.1.1	simple or compound surname	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.610.indicator.1.2	compound surname (obsolete)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.reindex.button_authorities	Reindex authorities base	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.option.author	Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.authorities.simple_search	Authorities Search	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.520.subfield.u	URI	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.user_current_lending_list	Copies on loan to this reader	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.210.subfield.b	Qualifier	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.210.subfield.a	Abbreviated Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.255.subfield.a	Scale	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.cataloging_label	Labels	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.vocabulary_680	Scope Note	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_700	Secondary Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.vocabulary_685	Background or Glossary Note	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.clean_install	New Library	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.acquisition_order_list	List orders	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.migration.groups.access_control	Access cards and access Control	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.distributed.query_placeholder	Fill in the terms for the search	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.distributed.any	Any	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.user_type.field.description	Description	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.accesscards.lend.success	Card successfully bound	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.change_status.title.unblock	Unblock Card	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.button.inactive	Mark as inactive	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.740.indicator.1	Number of characters to be overridden in alphabetation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.740.indicator.2	Type of secondary entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.manage.error.description	Failure creating a new library	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.topographic	Topographic Report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.title.title	Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.upload_popup.processing	Processing...	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.vocabulary.indexing_groups.up_term	Term of Use for (UF)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.750.indicator.2.4	Source not specified	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.select_item_button	Select record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.button.block	Block	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.reindex.button_vocabulary	Reindex vocabulary base	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.400	Other name form	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.administration_accesscards_delete	Delete access cards	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.download.field.languages	Language	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.error.block	Error when blocking Card	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.100.subfield.d	Dates associated to the name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.vocabulary_670	Origin of information	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.100.subfield.c	Title and other terms associated to the name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.410	Other name format	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.tabs.fines	Fines	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.100.subfield.q	Form of complete name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.expected_date	Expected date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.success.delete	Card successfully deleted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.button.unavailable	Unavailable	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.630.indicator.1	Number of characters to be overridden in alphabetation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.database.private	Private	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	digitalmedia.error.file_could_not_be_saved	The file sent could not be saved	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.user_id	User id	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.411	Other name format	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.750.indicator.2.0	Library of Congress Subject Headings	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.100.subfield.a	Surname and/or name of author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.100.subfield.b	Numeration following name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_590	Local notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.biblivre4restore.field.upload_file	Select backup file	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.daily_fine	Daily fine	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.600.indicator.1.0	Simple or compound name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.600.indicator.1.1	Simple or compound surname	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.600.indicator.1.2	Composed surname (obsolete)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.600.indicator.1.3	Family name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.advanced_search	Advanced Search	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.description.general.title	This configuration represents the name of the library, to be shown on the upper part of the Biblivre pages and in the reports.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.label_full	Complete Backup	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.title.search.result_limit	Result limit	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.gender	Gender	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.empty_lending_list	This reader does not have units (copies) lent	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.acquisition_supplier	Suppliers	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.access_control.card_not_found	Card not found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.usertype.confirm_cancel_editing_title	Cancel editing of User Type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.confirm_cancel_editing_title	Cancel addition of Access Cards	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.distributed.no_servers	A Z39.50 search is not possible as there are no remote libraries registered. In order to solve this problem, please registers Z39.50 servers of the libraries of interest in the option <em>" Z39.50 Servers"</em> within <em>"Administration"</em> in the upper Menu. For this a name of <strong>user</strong> and<strong>password</strong> is needed.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.editor	Publisher	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.source_file_title	Import records from a file	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.indexing_groups.year	Year	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.groups.digitalmedia	Digital Media	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.user_type.field.reservation_limit	Simultaneous reservations limit	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.users.failure.unblock	Failure unblocking User	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.field.expiration_date	Quotation expiration date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.change_password.submit_button	Change password	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.database.work	Work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.indicator.2	Number of characters to be overridden in alphabetation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.reader	Reader	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.indicator.1	Generates secondary entry in sheet	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.users.failure.block	Failure blocking User	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.450	Use For	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.045.subfield.b	Time period formatted from 9999 b.C onwards	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.045.subfield.a	Code of time period	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	digitalmedia.error.no_file_uploaded	No file sent	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.045.subfield.c	Time period formatted before 9999 b.C	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.210.indicator.2.0	Another abbreviated Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.days_late	Days behind schedule	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.error.order_not_found	It was not possible to find the order	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.manage.error.toggle	Error changing library status.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.holding_lent_to_the_following_reader	This copy was lent to the reader below	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_555	Notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.650.subfield.a	Topical Subject	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.sort_by	Sort by	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.accesscards.unbind_card	Return Card	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permission.error.create_login	Error when creating User login	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.210.indicator.1.0	Do not generate secondary Title entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.z3950.field.collection	Collection	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.button.delete	Delete	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.migration.migrate.error	Error when importing data	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_status.pending_issues	Has pending issues	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.210.indicator.1.1	Generate secondary Title entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.title	Reports	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.reindex.wait	Subject to the size of the database, this operation may take longer. Biblivre will not be available during this process as it may last up to 15 minutes.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.field.deadline_date	Valid until	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_651	Subject geography	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852	Information on location	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_650	Subject topic	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.option.database.work	Work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.administration	Administration	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.856	Work tracking by electronic means	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	login.error.login_already_exists	This login already exists. Choose another name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.field.requester	Requester	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.title	Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	format.datetime	dd/MM/yyyy HH:mm	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.configurations.error.disable_multi_schema_schema_count	It is not possible to disable the multi=libraries scheme when more than one library is enabled.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.button.new_holding	New unit	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.field.publisher	Publisher	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.error.no_card_found	No card found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.650.subfield.x	General subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.650.subfield.y	Chronological subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.650.subfield.z	Geographical subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	login.access_denied	Access denied. Invalid user or password	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.reindex.success	Reindexing concluded successfully	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.534.subfield.a	Fac-simile note	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.subfield.p	Name of the part - section of the work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.users.success.block	User blocked successfully	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.circulation_lending_lend	Conduct work loans	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.subfield.n	Number of the part - section of the work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.confirm_delete_record_question.forever	Do you really wish to delete the User Login?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.411	Another name format	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.subfield.l	Text language	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.error.select_reader_first	To lend a copy you need, in the first place, to select a reader	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.subfield.k	Subheadings	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.indexing_groups.all	Any field	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.labels.button.print_labels	Print labels	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.subfield.g	Additional information	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.subfield.f	Date of edition of item that is being processed	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.year	Year	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.subfield.d	Date that appears close to the uniform entry title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.subfield.a	Uniform title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_630	Subject Uniform Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.administration_indexing	Manage database indexing	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.685.subfield.i	Explanatory text	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.holding.confirm_delete_record.forever	It will be deleted forever from system and cannot be restored	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.button.save_as_new	Save as new	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.reservation.reserve_success	Reservation successfully made	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.z3950.page_help	<p> the Z39.50 server routine allows registration and search in Servers used  by the Distributed Search routine. To register the data of the Z39.50 collection are needed, as well as the URL address and access port.</p>\n<p>When accessing this routine, Biblivre will automatically list all the Servers previously registered. You may then filter the list, inserting the <em>Name</em> of a Server you may wish to find.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tabs.form	Form	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configurations.error.value_must_be_boolean	Value in this field must be true or false	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.110.indicator.1.2	name in the direct order	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.change_password.title	Password change	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	login.error.invalid_password	The field "current password" does not match with your password	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.confirm_delete_record_question	Do you really wish to delete this authority record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.110.indicator.1.0	inverted name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.110.indicator.1.1	name of jurisdiction	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.490.indicator.1.0	Unsplit title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.541.subfield.3	Material specifications	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.490.indicator.1.1	Split title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.590.subfield.a	Local notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.acquisition_request_list	List requests	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.invalid_pg_dump_path	Invalid path. Biblivre will not be able to create backups because the <strong>pg_dump</strong> file was not found.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.holdings.title	Search Copy (Unit)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.accession_number	Asset Cataloging Report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.description.cataloging.accession_number_prefix	Asset cataloging is the field that solely identifies a copy. In Biblivre, the rule for asset reference numbers depends on the year of acquisition of the unit, on the quantity of units entered in the year and on the prefix of the asset reference number. This prefix is the term to be included before the year number, in the format <prefix>.<year>.<counter> (Ex: Bib.2014.7).	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.confirm_delete_record.forever	It will be deleted from system forever and cannot be recovered	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.111.indicator.1.1	name of jurisdiction	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.111.indicator.1.2	name in direct order	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.111.indicator.1.0	Inverted name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.previous	Previous	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.restore.restore_with_new_schema_name	Restore this library using a new address	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.administration_usertype_list	List user types	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_cards.button.select_page	Select users in this page	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.administration_user_types	User Types	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_610	Subject collective entity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_611	Subject event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select_report	Select a Report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.680	Scope note (SC)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.description.general.business_days	This configuration represents the working days at the library and shall be used by the loan and reservation modules. The main use of this configuration is to avoid scheduling the return of the copy on a date in which the library is closed.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.wait	Wait	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.users	Users	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.685	Historical or glossary note (GLOSS)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.circulation	Circulation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.user_deleted	User deleted from system	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.cataloging_bibliographic	Bibliographic	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.fieldset.cataloging	Bibliographic Search	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.field.supplier_number	Taxpayer No.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.670	Note on the origin of term	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.reindex.error.invalid_record_type	Blank or unknown record type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.error.existing_card	Card already exists	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.upload.description	Select below the language file you wish to send for processing by BIBLIVRE 5.	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	search.authorities.page_help	<p>The search by Authorities allows retrieving information on the authors in the content of this library, if and when are cataloged </p>\n<p>The search will look for one of the terms inserted in the following fields: <em>{0}</em>.</p>\n<p>Terms are searched in its full format, however it is possible to use the asterisk (*) to look for incomplete terms, so that the search <em>'brasil*'</em> may find records containing, for example <em>'brasil'</em>, <em>'brasilia'</em> and <em>brasileiro</em>. Double quotation marks can be used to find two terms in sequence, so that the search <em>"my love"</em> may find records containing the two terms together, but it will not find records such as  in the text <em>'my first love'</em>.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.add_field	Add term	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.vocabulary_750	Topic Term	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	login.goodbye	Goodbye	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.user_type.error.no_user_type_found	No User Type found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.labels.button.select_page	Select items in this page	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.user_type.field.lending_time_limit	Loan term limit	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.tabs.lendings	Loans	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tabs.marc	MARC	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_600	Subject person	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.groups.login	Login	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.description.general.subtitle	This configuration represents a subtitle for the library, to be shown on the upper part of the Biblivre pages, just below the <strong>Name of Library </strong>. This is an optional configuration.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.360.subfield.y	Chronological subdivision adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.360.subfield.x	General subdivision adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.360.subfield.z	Geographical subdivision adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.selected_records_singular	{0} Value Added	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.material_type.map	Map	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.711.subfield.e	Name of event subunits	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.711.subfield.g	Additional information	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.711.subfield.a	Name of event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.711.subfield.c	Venue of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_cards.selected_records_singular	{0} user selected	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.711.subfield.d	Date of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.711.subfield.n	Name of order of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.711.subfield.k	Subheadings	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.fieldset.user	Search by User	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.711.subfield.t	Title of the work close to entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.490.subfield.a	Title of series	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.490.subfield.v	Number of volume or sequence designation of the series	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.080.subfield.a	Classification Number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.830.indicator.2	Number of characters to be overridden in alphabetation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configurations.error.value_is_required	Filling in this field is required	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.360.subfield.a	Topical term adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.field.area	Neighborhood	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.manage.success.create	New library successfully created.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.success.save	Request successfully included	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.indicator.1.3	3 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.indicator.1.2	2 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.group.cataloging	Cataloging	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.indicator.1.5	5 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.indicator.1.4	4 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.indicator.1.7	7 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.indicator.1.6	6 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.indicator.1.9	9 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.user_list_by_type	List of Users by Type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.reinstall.confirm.title	Go to the restoration and reconfiguration screen	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.indicator.1.8	8 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.button.import_all	Import all the pages	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.registered_between	Registered between	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.lendings_count	Total number of Books lent in the period	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.title.reservation	Reservations Report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.end_date	Final Date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.indicator.1.1	1 character to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.indicator.1.0	No character to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.subfield.p	Number of part - section of the work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.clean_install.button	Start as a new library	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.411.subfield.a	Name of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.repeat_password	Repeat password	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.confirm_delete_record_title.forever	Delete Order record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.help	Help	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.error.you_cannot_delete_yourself	You cannot delete yourself or mark you as inactive	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.button.list_all	List All	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.indicator.1.0	Does not generate entry for title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.prefix	Prefix	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.indicator.1.1	Generates entry for title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.custom_count	Bibliographic Record Count by Marc Field	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	error.invalid_handler	It was not possible to find a handler for this action	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.containing_text	Containing the text	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.material_type	Material type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.migration.button.migrate	Import data	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.expected_return_date	Expected return date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.indexing_groups.author	Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.041.indicator.1	Indication of translation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.cataloging_vocabulary_delete	Delete vocabulary record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.database.work_full	Work database	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tabs.holdings	Copies (Units)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.labels.paper_description	{paper_size} {count} labels ({height} mm x {width} mm)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.search_bibliographic	Bibliographic	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.subfield.b	Date that appears close to the uniform entry title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.subfield.a	Uniform title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.success.delete	Request successfully deleted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.page_help	<p>Supplier routine allows supplier registration and search. Searches will search for each one of the terms inserted in the fields <em>Fancy Name, Company Name or Taxpayer No. </em>.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.subfield.g	Additional information	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.subfield.f	Work date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.530.subfield.a	Notes on physical form availability	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.subfield.k	Subheadings	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.administration_maintenance	Maintenance	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.requester	Requester	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.subfield.n	Number of part - section of the work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.subfield.l	Text language	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.no_lendings	This user has no lendings	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.title.author	Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.field.id	Record Id	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.111.subfield.a	Name of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.confirm_cancel_editing_title	Cancel editing of authority record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_699	Subject local	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.111.indicator.1	Entry form	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.access_control.card_available	This card is available	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.400.subfield.a	Surname and/or Name of Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	label.login	Login	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.title	Permissions	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.button.import_this_page	Import records from this page	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configurations.error.invalid_writable_path	Invalid path. This directory does not exist or Biblivre is not authorized to write.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.541.subfield.d	Date of acquisition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.541.subfield.e	Number given to cquisition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.541.subfield.b	Address	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.541.subfield.c	Form of acquisition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.541.subfield.a	Name of source	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.740.indicator.1.1	1 character to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.740.indicator.1.2	2 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.reindex.description.4	Problems with the search, registered records are not found.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.740.indicator.1.0	No character to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.541.subfield.f	Owner	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.541.subfield.h	Purchase price	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.740.indicator.1.9	9 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.740.indicator.1.7	7 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.740.indicator.1.8	8 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.541.subfield.o	Type of unit	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.740.indicator.1.5	5 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.reindex.description.2	Modification in the configuration of searchable fields;	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.541.subfield.n	Quantity of items purchased	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.740.indicator.1.6	6 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.change_status.uncancel	Card will be recovered and will be available for use	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.reindex.description.3	Import of old Biblivre records; and	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.830	Secondary entry - Series - Uniform Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.740.indicator.1.3	3 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.740.indicator.1.4	4 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.reindex.description.1	Database reindexing is a process thorugh which Biblivre analyzes each record registered, and creates indexes in certain field in order to make searches possible. This is a lengthy process that has to be executed only in the specific cases below:<br/>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.306.subfield.a	Duration time	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.active_lendings	Active lendings	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.button.remove_login	Remove Login	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.subfield.a	Location	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.reservation.button.select_reader	Select reader	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.subfield.b	Sub-location or collection	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.subfield.c	Location on rack	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configurations.error.save	Impossible to save configurations	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.subfield.e	Mail address	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.label.example	ex.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.reservation.button.reserve	Reserve	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.500.subfield.a	General notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.field.quantity	Quantity of copies	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.administration_z3950_servers	Z39.50 Servers	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.title.quantity	Quantity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	login.error.same_password	The new password must be different from the current password	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.usertype.confirm_cancel_editing.1	Do you wish to cancel editing this User Type?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.usertype.confirm_cancel_editing.2	All the modifications will be lost	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.field.code	Card	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.user_type.success.save	User Type successfully included	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.suffix	Suffix	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.400.subfield.a	Surname and/or name of author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.360.subfield.a	Topical term adopted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.late_lendings	Late Loans Report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.subfield.z	Public note	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.856	Tracking of works through electronic means	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.710.indicator.2.2	analytical entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.indexing_groups.other_name	Other name format	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.title.general.currency	Currency	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.subfield.q	Condição física da parte	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.subfield.x	Internal note	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.field.delivered	Order received	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.subfield.u	URI	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.group.acquisition	Acquisition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.field.supplier_select	Select a Supplier	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.multi_schema_translations	Translations	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.subfield.j	Control number in rack	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.button.select_page	Select records from this page	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.on_the_field	In the field	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.subfield.n	Country code	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.111.subfield.e	Name of subunits of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.111.subfield.c	Venue for the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.material_type	Type of material	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.111.subfield.d	Date of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.fieldset.contact	Contacts/Phone numbers	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.111.subfield.g	Additional information	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.111.subfield.n	Number of order of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.111.subfield.k	Subheadings	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.labels.selected_records_plural	{0} units (copies/items) selected	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_400	Another name format	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.common.button.upload	Send	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.362	Information on Publication and/or Volume Dates	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.360	Remissive SA (see also) and AT (related or associated term)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.field.supplier_select	Select a Supplier	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.shelf_location	Location	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.700.indicator.2._	no information provided	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.error.dump	It was not possible to generate translation file	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.error.couldnt_unzip_backup	Backup selected could not be unzipped	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.confirm_delete_record_title	Delete requisition record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.error.invalid_database	Invalid database	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.created	Registered in	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.confirm_delete_record_question	Do you really wish to delete this Order record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.administration_reports	Create Reports	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.option.classification	Classification (CDD)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.field.url	URL	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.error.no_record_found	No valid Record was found in the file	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.manage.enable	Enable library	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.database.record_count	Records in this base: <strong>{0}</strong>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.reservation.holdings.title	Search Bibliographic record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.confirm_delete_record_title	Delete authority record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.confirm_delete_record_question	Do you really wish to exclude this bibliographic record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	format.date_user_friendly	DD/MM/YYYY	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.select_restore.library_list_inside_backup	Libraries in this backup	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.title.holdings_creation_by_date	Reporto n Total Work Inclusions by Period	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.birthday	Date of Birth	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.field.complement	Complement	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.750	Topical term	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.user_type	User Type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.fine_popup.description	This is a 'behind schedule' (late) return and is subject to a fine. Please check below the information presented and confirm if the fine will be added to the user records in order to be paid in the future (Fine), if it was paid together with the return (Pay) or if it will be exempted (Exempt).	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.340	Physical carrier	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permission.success.permissions_saved	Permissions modified successfully	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.343	Data of flat coordinate	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_013	Information from patent control	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.342	Data on geospatial reference	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.added_to_list	Added to list	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.marc_popup.description	Use the box below to modify the MARC of this record before importing it.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.710.indicator.1.2	name in direct order	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.710.indicator.1.0	inverted name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.reindex.confirm	Do you wish to confirm base reindexing?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.710.indicator.1.1	name of jurisdiction	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.090.subfield.b	Code of author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.090.subfield.a	Classification	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.search_vocabulary	Vocabulary	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.modified	Cancellation/Alteration Date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.740	Secondary entry - Additional Title - Analytical	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_410	Another name format	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_411	Another name format	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.090.subfield.d	Copy number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.090.subfield.c	Edition / volume	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.biblivre4restore.error	Backup restoring error	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_020	ISBN	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.indicator.2.9	9 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.indicator.2.8	8 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.indicator.2.7	7 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_024	ISRC	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.button.print_receipt	Print receipt	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_022	ISSN	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.indicator.2.2	2 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.indicator.2.1	1 character to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.indicator.2.0	No character to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.indicator.2.6	6 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.indicator.2.5	5 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.indicator.2.4	4 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.form.remove	Remove	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.240.indicator.2.3	3 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.362.indicator.1	Date format	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.acquisition_quotation_save	Save quotation record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.field.info	Remarks	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.title.orders_by_date	Report on Orders by Period	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.lend_success	Copy (unit) lent successfully	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.error.invalid_origin_schema	Backup did not have selected library	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.button.edit	Edit	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.confirm_cancel_editing.2	All the modifications will be lost	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.confirm_cancel_editing.1	Do you wish to cancel editing this quotation record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.confirm_cancel_editing.1	Do you wish to cancel inclusion of Access Cards?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.confirm_cancel_editing.2	All the modifications will be lost	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.label_exclude_digital_media	Backup without digital files	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.administration_permissions	Logins and Permissions	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.541.indicator.1	Privacy	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.circulation_list	List users	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.isrc_already_in_database	There is already a record with this ISRC in the database	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.address_state	State	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.button.save_as_new	Save as new	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.610.indicator.1	Form of entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.subfield.z	Geographical subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.indexing_groups.isrc	ISRC	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.select.default	Select an option	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.help_about_biblivre	About Biblivre	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.subfield.x	General subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.subfield.y	Chronological subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.save.success	Records imported successfully	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.confirm_cancel_editing_title	Cancel edition of supplier registration	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.upload_popup.uploading	Sending file...	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	field.error.required	Filling in this field is compulsory	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.created	Registration Date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.reservation.reserve_date	Reservation date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permission.success.create_login	Login and permissions successfully created	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	error.file_not_found	File not found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.indexing_groups.issn	ISSN	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.indexing_groups.notes	Notes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
es	cataloging.bibliographic.indexing_groups.notes	Notas	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
pt-BR	cataloging.bibliographic.indexing_groups.notes	Notas	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.043.subfield.a	Code of geographical area	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.reservation.reservation_count	Records reserved	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.help_about_library	About the Library	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.restore.restore_partial_backup.description	To restore only some libraries, use the form below. In this case you may either choose the libraries to be restored and they will replace the existing ones, or they will be restored as new libraries. This is useful for duplicating libraries or for checking if backup is correct.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.title.administration.z3950.server.active	Local active server z39.50	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.indexing_groups.entity	Entity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.users.success.save	User successfully included	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.310.subfield.a	Usual Periodicity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.holdings_reserved	Reserved	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.310.subfield.b	Date of usual periodicity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.090	Call number / Location	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.acquisition_request_delete	Delete requests record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.vocabulary.indexing_groups.vt_ta_term	Associated Term (AT)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.biblivre4restore.newest_backup	Most recent Backup	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.biblivre4restore.description_found_backups_1	See below backups found in the documents in your computer. To restore these backups, press the button on your name.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.150	Narrower Term (NT)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.circulation_lending_return	Conduct work returns	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.users.failure.delete	Failure deleting user	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.confirm_cancel_editing_title	Cancel editing of requisition record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.add_cards	Ad Cards	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.description.general.pg_dump_path	Attention: This is an advanced configuration, although important. Biblivre will endeavor to automatically find the path for the program <strong>pg_dump</strong> and except in cases when an error is show below, you will not need to modify this configuration. This configuration represents the path on the server where Biblivre is installed, for the executable <strong>pg_dump</strong> which is distributed with the PostgreSQL. Should this configuration be invalid, Biblivre will not be able to create safety copies.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.cataloging_authorities_move	Move authority record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.confirm_move_record_description_singular	Do you really wish to mover this record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.change_status.title.cancel	Cancel Card	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.reindex.warning	This process may take some minutes, subject to the hardware configuration of your server. During this, Biblivre will not be available for record searches, but will operate again when reindexing finishes.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.user.simple_term_title	Fill in the terms for the search	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.receipt.title	Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.paid_value	Total Value Paid	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.reservation.delete_failure	Reservation delete failure	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.082.subfield.a	Classification Number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.button.lend	Lend	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.acquisition	Acquisition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.913	Local code	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.vocabulary_150	Narrower Term	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.confirm_delete_record_question	Do you really wish to delete this quotation record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.fieldset.database	Database	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.clear_simple_search	Clear search results	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.source_search_subtitle	Select a remote library and fill in the search terms. The search will provide a limit of  {0} records. If you do not see the record that interests you, please refine your search.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.vocabulary_550	Broader Term	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.phone_work_extension	Extension of commercial telephone number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.confirm_delete_record_title.forever	Delete user	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.confirm_cancel_editing.1	Do you wish to cancel editing this bibliographic record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.holding.confirm_cancel_editing_title	Cancel editing unit record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.late_lendings_count	Total of late loans	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.confirm_cancel_editing.2	All the modifications will be lost	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.no_records_found	No records found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.subfield.d	Date that appears close to the uniform entry title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.field.receipt_date	Receipt date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.title.user	Report by User	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.subfield.p	Name of part - section of the work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.number_of_holdings	Number of Copies	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.database.main	Main	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.subfield.f	Date of edition of the item that is being processed	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.subfield.g	Additional information	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.page_help	<p>Requisition routine allows registration and search of work requisitions. A requisition is a record on a work the Library wishes to purchase and can be used to conduct Quotations with previously registered Suppliers.</p>\n<p>Search will look for each one of the terms inserted in the fields <em>Requester, author or Title </em>.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.no_reserves	This user has no reservations	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.subfield.l	Text language. Language of the text in full	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730.subfield.k	Subheadings	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.error.no_language_code_specified	The translations file sent does not have the language identifier: <strong>*language_code</strong>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.082.subfield.2	Number of edition of the CDD	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.confirm_delete_record_question.forever	Do you really wish to delete this quotation record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.210.indicator.1	Secondary Title entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.210.indicator.2	Title Type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.user_data	Data	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.distributed.title	Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permission.success.password_saved	Password modified successfully	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_490	Series	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.750.indicator.1.0	No specified level	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.750.indicator.1.1	Primary subject	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.750.indicator.1.2	Secondary subject	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.z3950.confirm_delete_record.forever	The Z39.50 Server will be deleted forever from the system and cannot be restored	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_status.inactive	Inactive	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.field.name	Company Name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.unavailable	Backup unavailable	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.change_status.question.block	Do you really wish to block this Card?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.z3950.confirm_delete_record_title.forever	Delete Z39.50 Server	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.change_status.title.block	Block Card	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.digitalmedia_upload	Upload digital media	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.fine.success_pay_fine	Fine paid successfully	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.circulation_lending	Loans and Returns	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.holdings_count	Copies	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.100.subfield.a	Surname and/or name of author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.step_1_title	Select origin of import data	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.100.subfield.b	Numbering that follows the name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.651.subfield.y	Chronological subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.title.cataloging.accession_number_prefix	Prefix of asset reference number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.error.duplicated_destination_schema	It is not possible to restore two libraries for a single shortcut	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.651.subfield.x	General subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.reservation.record_list_reserved	List only records reserved	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.651.subfield.z	Geographical subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.indexing_groups.event	Event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.error.javascript_locale_not_available	There is no JavaScript language identifier for the translations file	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.321	Previous Periodicity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.z3950.no_server_found	No z39.50 server found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	error.invalid_user	Invalid or non-existing user	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.user_late_lendings	Late loans	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.migration.description	Select below the items you wish to import from the Biblivre 3 database	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.manage.error	Error	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.field.total_value	Total value	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.field.supplier	Supplier	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.selected_records_singular	{0} record selected	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.020.subfield.a	ISBN number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.020.subfield.c	Acquisition arrangement	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.button.select_reader	Select reader	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.material_type.score	Score	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.indicator.2	Order type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.migration.groups.digital_media	Digital Media	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.address_number	Number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.100.subfield.q	Complete form of the name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.error.no_quotation_found	No quotation found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.marc_field	Marc Field	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.100.subfield.d	Dates associated to name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.100.subfield.c	Title and other words associated to the name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.852.indicator.1	Classification scheme	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.field.delivery_time	Delivery time (as promised)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.field.address	Address	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.authorities_100	Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.biblivre_report_header	Biblivre reports	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.option.all_digits	All	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	field.error.digits_only	This field must be filled in with numbers	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.300	Physical description	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.change_password.repeat_password	Repeat new password	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.306	Duration time	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.error.card_not_found	No Card found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.button.select_user	Select User	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.confirm_delete_record_title.forever	Delete Access Card	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.342.indicator.1.0	Horizontal coordinate system	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.651.subfield.a	Geographical name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.change_status.unblock	Card will be unblocked and will be available for use	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.change_status.block	Card will be blocked and will not be available for use	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.310	Usual Periodicity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.342.indicator.1.1	Vertical coordinate system	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.circulation_access_control_list	List access control	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.user_type.success.delete	User Type successfully deleted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.database.title	Selected database	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.cataloging_vocabulary_save	Save vocabulary record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.error.existing_cards	The following Cards already exist:	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.subfield.a	Work title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.title.holdings_by_date	Copies Registration Report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.subfield.l	Text language	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.342.indicator.2.0	Geographical	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.next	Next	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.subfield.k	Subheadings	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.342.indicator.2.1	Map  projection	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.field.quotation_select	Select one Quotation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.342.indicator.2.2	System of grid coordinates	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.342.indicator.2.3	Flat place	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.342.indicator.2.4	Place	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.authorities_110	Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.subfield.g	Additional information	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.342.indicator.2.5	Geodesic model	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.lendings_current	Total number of Books still on loan	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.authorities_111	Author Event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.342.indicator.2.6	Altitude	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.invalid_psql_path	Invalid path. Biblivre cannot create and recover backups because the <strong>psql</strong> file was not found.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.342.indicator.2.7	To specify	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.success.delete	Supplier successfully deleted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.342.indicator.2.8	Depth	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.change_status.question.uncancel	Do you really wish to recover this Card?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.subfield.f	Date of work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.700.subfield.l	Text language	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.import_popup.title	Importing Records	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.700.subfield.t	Title of the work close to the entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.258.subfield.b	Denomination	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.acquisition_supplier_list	List suppliers	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.258.subfield.a	Issuing jurisdiction	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.700.subfield.q	Complete form of name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.gender.1	Male	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.gender.2	Female	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.groups.admin	Administration	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.unit_value	Unit Value	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.author_type	Author type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.records	Report on Inclusion of Works during Period	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.administration_accesscards_save	Include access cards	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.700.subfield.c	Title and other terms associated to the name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.700.subfield.d	Dates associated to the name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.700.subfield.a	Surname and/or name of author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.700.subfield.b	Numbering following name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.error.save	Error saving quotation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.700.subfield.e	Relation to the document	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.confirm_delete_record.trash	It will be moved to the trash recycle bin	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_field.type	User Type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.title.title	Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.indicator.1.1	Generates entry for title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.243.indicator.1.0	Does not generated entry for title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.680.subfield.a	Scope note	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.130.indicator.1	Number of characters to be overridden in the alphabetation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field_count.description	<p>After selecting the Marc field and Ordering, please conduct bibliographic search that will be the basis for the report, or press <strong>Issue Report</strong> to use the complete bibliographic base.</p>\n<p><strong>Attention:</strong> Issuance of this report may take some minutes, depending on the size of the bibliographic base.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.end_number	End number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.modified_between	Modified between	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.form.hidden_subfields_singular	Show hidden subfield	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.z3950.error.save	Error saving Z39.50 Server	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.backup.schemas.description	Select below all the libraries that will make up the backup. If a backup has several libraries, you will be able to choose the ones to be restored when necessary.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.administration_access_cards	Access Cards	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.field.quantity	Quantity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.acquisition_order_save	Save order record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.administration_restore	Restore database backup	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.id_rg	Identity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.download.button	Download the language	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.button.edit	Edit	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.label_digital_media_only	Backup of digital files	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.user_type.field.reservation_time_limit	Reservation time	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.600.subfield.k	Subheadings	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	format.datetime_user_friendly	DD/MM/YYYY hh:mm	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.acquisition_supplier_save	Save supplier record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.operator	Operator	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.600.subfield.t	Title of the work close to the entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.600.subfield.q	Complete format of the name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.confirm_delete_record_question.forever	Do you really wish to delete this requisition record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_710	Secondary Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.record_will_be_ignored	This record will not be imported	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_711	Secondary Author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.600.subfield.d	Dates associated to the name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configurations.error.value_must_be_numeric	The value in this field must be numeric	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.title.summary	Catalogue Summary Report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.550	BT (broader term)	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.600.subfield.a	Name and/or surname of author	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.field.status	Status	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_field.id	User number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.600.subfield.b	Numbering following name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.600.subfield.c	Title and other terms associated to the name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.confirm_remove_attachment_description	Do you wish to delete this digital file?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.user_type.simple_term_title	Fill in User Type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	warning.reindex_database	You need database reindexing	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.groups.cataloging	Cataloging	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.user.select_item_button	Select record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.advanced_search	Bibliographic Advanced Search	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.600.subfield.z	Geographical subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.amount	Quantity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.600.subfield.x	General subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.600.subfield.y	Chronological subdivision	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.users_without_user_card	List only users that never had their library card printed	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.confirm_remove_attachment	Delete digital file	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.confirm_delete_record_question	Do you really wish to delete this requisition record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.111.subfield.k	Subheadings	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.holding.error.accession_number_unavailable	This asset reference number is already in use by other unit. Please fill in another value or leave it blank so that the system can make the calculation automatically.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.confirm_delete_record_title.forever	Delete requisition record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.author_type.100	Person	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.button.add	Add	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.change_status.title.uncancel	Recover Card	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.field.created	Order date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_730	Uniform Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.records_found_plural	{0} records found	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.100.indicator.1	Entry form	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.holding.error.shouldnt_delete_because_holding_is_or_was_lent	This unit is or was already lent and must not be deleted. Should it be no longer available, the correct procedure is to change from 'available' to 'unavailable'. However, if you still wish to delete this unit, press button <b>"Force Deletion "</b>.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.page_help	<p>The <strong>"User Registry"</strong> allows storing information on readers and library employees in order to facilitate lendings, reservations and also to control access of these users to the library.</p>\n<p>Before registering a user it is recommended to check whether he/she is already registered, through a <strong>Simple search</strong>, which will search each of the terms inserted in the selected field or through an <strong>Advanced research </strong>, which provides a better control on users found, allowing, for example, searching users with pending fines.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.author_type.110	Collective Entity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.order.selected_records_plural	{0} Values Added	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.author_type.111	Event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.button.unblock	Unblock	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.710.subfield.a	Name of entity or of place	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.710.subfield.b	Subordinated units	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.field.edition	Edition number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.710.subfield.c	Venue of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.field.city	City	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.710.subfield.d	Date of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.710.subfield.g	Additional information	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	aquisition.quotation.error.quotation_not_found	It was not possible to find the quotation	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.710.subfield.l	Text language	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_740	Analytical Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.710.subfield.n	Number of part - section of the work	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.success.save	Language file processed successfully	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.110.indicator.1.1	Name of jurisdiction	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.administration_translations	Translations	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.indexing_groups.isbn	ISBN	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.110.indicator.1.0	Inverted name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.710.subfield.t	Title of the work close to entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.110.indicator.1.2	Name in the direct order	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.type.vocabulary	Vocabulary	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	menu.circulation_reservation	Reservations	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.300.subfield.b	Illustrations	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.300.subfield.a	Number of volumes and/or pages	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.300.subfield.c	Dimensions	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.option.location	Location	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.indicator.2	Type of title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.246.indicator.1	Note control/secondary title entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.record.success.save	Record successfully included	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.user_type.success.update	User Type successfully saved	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.custom.user_field.phone_work	Commercial Telephone No.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.300.subfield.e	Additional material	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.300.subfield.f	Type of storage unit	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.300.subfield.g	Size of storage unit	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.users.failure.disable	Failure marking user as inactive	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_090	Location	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.bibliographic.id	Record Id	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.library	Library	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.setup.upload_popup.title	Opening file	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.740.indicator.2.2	analytical entry	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.manage.schemas.title	List of Libraries in this Server	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.estimated_fine	Estimated fine in case of return today	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.confirm_delete_record.forever	It will be permanently deleted from the system and cannot be retrieved.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.migration.migrate.success	Data imported successfully	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.041	Language code	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.040	Cataloging source	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	search.common.button.filter	Filter	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.043	Code of geographical area	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.configurations.error.disable_multi_schema_outside_global	It is not possible to disable the multi-libraries scheme  within a library.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.backup_never_downloaded	This backup was never downloaded	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.045	Code for the chronological period	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.confirm_cancel_editing.1	Do you wish to cancel editing this authority record?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.confirm_cancel_editing.2	All the modifications will be lost	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_082	CDD	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.authorities.indexing_groups.total	Total	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user.fine.pending	Pending	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_080	CDU	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.upload.field.user_created	Upload translations created by the user	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.error.corrupted_backup_file	Backup selected is not a valid file or is corrupt	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.labels.popup.title	Labels format	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.indicator.2.6	6 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.indicator.2.7	7 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.indicator.2.8	8 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.300.subfield.3	Additional Material Specification	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.indicator.2.9	9 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.title.general.business_days	Business days	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.indicator.2.2	2 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.indicator.2.3	3 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.indicator.2.4	4 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.indicator.2.5	5 characters to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.555.indicator.1	Constant exhibition control	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.migration.title	Biblivre 3 data migration	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.indicator.2.0	No character to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.245.indicator.2.1	1 character to be overridden	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.select.option.bibliography	Author Bibliography Report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.supplier.field.vat_registration_number	State registration number	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.database.record_moved	Record moved to {0}	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.receipt.renews	Renewals	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tabs.brief	Catalographic Summary	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.vocabulary.datafield.685.subfield.i	Explanatory text	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.reinstall.confirm.question	Your attention, please. All the options will delete the data in your library in favor of the retrieved data. Do you wish to continue?	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.select.default	Select an option	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.541	Note on acquisition source	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_095	Area is known by the CNPq	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.button.new	New record	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.029	ISNM	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.user_status.inactive	Inactive	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.material_type.nonmusical_sound	No musical sound	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.022	ISSN	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.024	Other standardized numbers or codes	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.595.subfield.b	Notes for bibliography, indices and/or appendices	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.595.subfield.a	Bibliography code	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.020	ISBN	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.343.subfield.a	Method for codification of flat coordinate	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.343.subfield.b	Flat distance unit	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.title.circulation.lending_receipt.printer.type	Type of printer for loan receipts	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.111.subfield.n	Number of order of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	login.error.user_has_login	This user already has a login	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.711.indicator.1.2	name in direct order	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.close	Close	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.711.indicator.1.1	name of jurisdiction	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.111.subfield.e	Name of event subunits	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.711.indicator.1.0	inverted name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_041	Language	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.111.subfield.d	Event date	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.111.subfield.c	Venue for the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.translations.error.invalid_file	Invalid file	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_043	Geographical Code	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.import.save.failed	Error when importing Records	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.success.update	Request successfully saved	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.tab.record.custom.field_label.biblio_045	Chronological Code	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.111.subfield.g	Additional information	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.upload_popup.title	Sending File	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.form	Form	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	format.date	dd/MM/yyyy	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.111.subfield.a	Name of the event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.user_type.page_help	<p>The Users Type routine allows registration and search of Users types used by the Users Registration routine. Herein you will find definitions about pieces of information such as Limits of simultaneous Loans, terms for loan returns and daily fines for each type of user separately.</p>\n<p>When accessing this routine, Biblivre will automatically list all the types of Users previously registered. You will be able to filter that list, inserting the <em>Name</em> of a Type of User you wish to trace.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.accesscards.success.unblock	Card unblocked successfully	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.110	Author - Collective entity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.013	Information about patent control	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.111	Author - Event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.login	Login	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.configuration.title.general.subtitle	Subtitle of this Group of Libraries	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.730	Secondary entry - Uniform title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.holding.datafield.949	Asset cataloging reference	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	error.invalid_parameters	Biblivre could not understand parameters received	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.525.subfield.a	Supplementary Note	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.bibliographic.indexing_groups.title	Title	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.success.save	Quotation successfully included	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.items.administration_permissions	Manage permissions	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.title.late_lendings	Late Lendings Report	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.configuration.description.general.backup_path	This configuration represents the path on the server where Biblivre is installed, for the file in which Biblivre security copies are to be kept. Should this configuration be empty, security copies will be save on the directory <strong>Biblivre</strong> in the folder of the user of the system.<br> The recommendation is to associate this path to any kind of automatic backup in cloud such as the services <strong>Dropbox</strong>, <strong>SkyDrive</strong> or <strong>Google Drive</strong>. Should Biblivre be unable to keep the files in the specified path, they will be kept in a temporary directory and may not become available. Please remember that a backup is the only way to retrieve data inserted in Biblivre.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.request.field.author_type	Author type	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.lending.lending_count	Copies lent	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.permissions.confirm_delete_record_title.forever	Delete User Login	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.authorities.datafield.100	Author - Personal name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.title.user_creation_count	Total of Inclusions by User	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.700	Secondary entry - Personal name	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.unblock	Unblock	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.maintenance.backup.error.invalid_schema	Backup list has one or more invalid libraries	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	common.calculating	Calculating	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.material_type.all	All	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.field.requisition	Requisition	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	multi_schema.manage.error.create	Failure creating new library.	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.710	Secondary entry - Collective Entity	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.711	Secondary entry - Event	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.vocabulary.confirm_delete_record.forever	It will be deleted forever from the system and cannot be restored	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	acquisition.quotation.success.delete	Quotation successfully deleted	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	marc.bibliographic.datafield.740.indicator.2._	no information provided	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	administration.reports.field.lendings	Loans	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	circulation.user_cards.selected_records_plural	{0} users selected	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
en-US	cataloging.lending.error.limit_exceeded	The selected reader surpassed the limit of authorized loans	2014-07-26 10:56:18.338867	1	2014-07-26 10:56:18.338867	1	f
es	multi_schema.restore.title	Opciones de Restauración de Backup	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.select_restore.description_found_backups	Abajo están los backups encontrados en la carpeta <strong>{0}</strong> del servidor Biblivre. Pulse sobre el backup para ver la lista de opciones de restauración disponibles.	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.restore.warning_overwrite	Atención: ya existe una biblioteca registrada con la dirección arriba. Si usted efectuara la restauración con esta opción seleccionada, el contenido de la biblioteca existente será sustituido por el contenido del Backup.	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.backup.schemas.title	Copia de Seguridad (Backup) de Bibliotecas Múltiples	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	administration.maintenance.backup.error.invalid_destination_schema	El atajo de destino es inválido.	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.select_restore.title	Restauración de Backup de Bibliotecas Múltiples	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.restore.restore_with_original_schema_name	Restaurar esta biblioteca usando su dirección original.	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.manage.error.cant_disable_last_library	No es posible deshabilitar todas las bibliotecas de este grupo. Al menos una debe quedar habilitada.	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	administration.maintenance.backup.error.backup_file_not_found	Archivo de backup no encontrado	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.restore.dont_restore	No restaurar esta biblioteca	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.restore.restore_complete_backup.description	En caso de desear restaurar todo el contenido de este backup, use la tecla abajo. Atención: Esto sustituirá TODO el contenido de su Biblivre, incluso sustituyendo todas las bibliotecas existentes por las que se encuentran en el backup. Use esta opción solo si desea retornar completamente en el tiempo, hasta la fecha del backup.	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.restore.restore_partial_backup.title	Restaurar bibliotecas de acuerdo con los criterios arriba.	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.manage.disable	Deshabilitar biblioteca	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.restore.restore_complete_backup.title	Restaurar todas las informaciones del Backup, substituyendo todas las bibliotecas de este Biblivre.	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.manage.error.toggle	Error al cambiar el estado de la biblioteca.	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.configurations.error.disable_multi_schema_schema_count	No es posible deshabilitar el sistema de multi bibliotecas mientras exista más de una biblioteca habilitada.	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.restore.restore_with_new_schema_name	Restaurar esta biblioteca usando una nueva dirección.	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.select_restore.library_list_inside_backup	Bibliotecas en este backup	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	administration.maintenance.backup.error.invalid_origin_schema	El Backup no posee la biblioteca seleccionada.	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.restore.restore_partial_backup.description	Para restaurar solo algunas bibliotecas, use el formulario siguiente. En este caso usted podrá elegir qué bibliotecas serán restauradas y si ellas sustituirán a las existentes o si serán restauradas como nuevas bibliotecas. Esto es útil para duplicar bibliotecas o verificar si el backup está correcto.	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.manage.enable	Habilitar biblioteca	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	administration.maintenance.backup.error.duplicated_destination_schema	No es posible restaurar dos bibliotecas para un único atajo.	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.backup.schemas.description	Seleccione abajo todas las bibliotecas que formarán parte del backup. Aunque un backup contenga distintas bibliotecas, usted podrá elegir cuál desea restaurar cuando así lo precise.	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
es	multi_schema.configurations.error.disable_multi_schema_outside_global	No es posible deshabilitar el sistema de multi bibliotecas del interior de una biblioteca.	2014-07-26 10:56:23.669888	1	2014-07-26 10:56:23.669888	1	f
pt-BR	multi_schema.restore.restore_partial_backup.description	Para restaurar apenas algumas bibliotecas, use o formulário abaixo. Neste caso você poderá escolher quais bibliotecas serão restauradas e se elas substituirão as existentes ou se serão restauradas como novas bibliotecas. Isto é útil para duplicar bibliotecas ou verificar se o backup está correto.	2014-07-19 13:48:01.039737	1	2014-07-26 10:56:27.710005	1	f
en-US	cataloging.bibliographic.automatic_holding_help	<p>Use the form below to speed up the Copies creation process. This is an optional step and no holding will be created if the form below is left blank. In that case, you can create your holdings in the <em>Copies</em> tab.</p><p>If you want to create the Copies now, the only mandatory field is "Number of Copies". This field will decide the number of copies created for each volume, so, if the bibliographic record has 3 volumes and you set "Number of Copies" as 2, 6 copies will be created, 2 for each volume. If there's only one volume, fill in the "Volume Number" field, and if there's no volume, leave both fields blank.</p>	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	administration.configuration.title.logged_in_text	Greeting message for logged users	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	circulation.user_reservation.page_help	<p>To reserve your selected book, please search for it below, just like in the Bibliographic Search module.</p>	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	warning.download_site	Go to download site	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	administration.reports.field.id	Registration No.	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	cataloging.bibliographic.automatic_holding.holding_count	Number of copies	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	administration.configuration.title.logged_out_text	Greeting message for unlogged users	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	cataloging.bibliographic.automatic_holding_title	Automatic Copies Creation	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	administration.permissions.items.circulation_reservation_list	List reserves	2014-07-26 10:56:18.338867	1	2014-07-26 12:01:11.320131	1	f
en-US	administration.reports.field.biblio_reservation	Reserves by bibliographical record	2014-07-26 10:56:18.338867	1	2014-07-26 12:01:11.320131	1	f
en-US	marc.bibliographic.datafield.730.indicator.2._	no information provided	2014-07-26 10:56:18.338867	1	2014-07-26 12:01:11.320131	1	f
en-US	menu.circulation_user_reservation	Reserves	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	administration.configuration.description.logged_in_text	Message that will show at Biblivre's welcome screen, for users that have logged in. You may use HTML tags, but be careful not to break Biblivre's layout. Warning: this configuration is related to the Translations module. Changes made here will only affect the current language. To change other languages, use the Translations Module or open Biblivre in the desired language.	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	administration.reports.field.holdings_count	Number of copies	2014-07-26 10:56:18.338867	1	2014-07-26 12:01:11.320131	1	f
en-US	menu.multi_schema_backup	Backup and Restore	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	cataloging.bibliographic.automatic_holding.holding_acquisition_date	Acquisition date	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	cataloging.bibliographic.automatic_holding.holding_library	Depository Library	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	menu.self_circulation	Reserves	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	administration.permissions.items.circulation_reservation_reserve	Reserve	2014-07-26 10:56:18.338867	1	2014-07-26 12:01:11.320131	1	f
en-US	administration.configuration.description.logged_out_text	Message that will show at Biblivre's welcome screen, for users that haven't logged in. You may use HTML tags, but be careful not to break Biblivre's layout. Warning: this configuration is related to the Translations module. Changes made here will only affect the current language. To change other languages, use the Translations Module or open Biblivre in the desired language.	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	administration.reports.field.holding_reservation	Reserves by Holding Id	2014-07-26 10:56:18.338867	1	2014-07-26 12:01:11.320131	1	f
en-US	administration.migration.groups.reservations	Reserves	2014-07-26 10:56:18.338867	1	2014-07-26 12:01:11.320131	1	f
en-US	marc.bibliographic.datafield.730.subfield.a	Uniform title given to document	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	cataloging.bibliographic.automatic_holding.holding_acquisition_type	Acquisition Type	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	administration.permissions.items.circulation_user_reservation	Reserve a book yourself	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	cataloging.bibliographic.automatic_holding.holding_volume_number	Volume number	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	cataloging.bibliographic.automatic_holding.holding_volume_count	Number of volumes	2014-07-26 12:01:11.320131	1	2014-07-26 12:01:11.320131	1	f
en-US	acquisition.quotation.confirm_delete_record.trash	It will be sent to the "trash" recycle bin database	2014-07-26 10:56:18.338867	1	2014-07-26 13:41:48.22945	1	f
en-US	circulation.user.confirm_delete_record.inactive	He will be deleted from the search list and will only be found through an "advanced search", from which he can be excluded forever, or recovered	2014-07-26 10:56:18.338867	1	2014-07-26 13:41:48.22945	1	f
en-US	cataloging.database.trash_full	Recycle "trash" bin	2014-07-26 10:56:18.338867	1	2014-07-26 13:41:48.22945	1	f
en-US	cataloging.vocabulary.confirm_delete_record.trash	It will be moved to the recycle-bin "trash" database"	2014-07-26 10:56:18.338867	1	2014-07-26 13:41:48.22945	1	f
en-US	cataloging.holding.confirm_delete_record.trash	It will be moved to the recycle "trash" bin	2014-07-26 10:56:18.338867	1	2014-07-26 13:41:48.22945	1	f
en-US	marc.bibliographic.datafield.501	Notes starting with the term "with"	2014-07-26 10:56:18.338867	1	2014-07-26 13:41:48.22945	1	f
es	administration.setup.biblivre4restore.error.digital_media_only_selected	La copia de seguridad seleccionada contiene sólo los archivos digitales. Trate de usar una copia de seguridad completa o parcial sin archivos digitales	2022-12-04 11:05:55.396257	0	2022-12-04 11:05:55.396257	0	f
pt-BR	administration.setup.biblivre4restore.error.digital_media_only_should_be_selected	O segundo arquivo de backup selecionado não contém apenas arquivos digitais	2022-12-04 11:05:55.397375	0	2022-12-04 11:05:55.397375	0	f
en-US	circulation.user_cards.page_help	<p>The module<strong>"Printing User Cards"</strong> allows generating the identification labels of the library readers.</p>\n<p>It is possible to generate the user cards for one or more readers in a single printing, using the search below.</p>\n<p>After finding the reader(s), use the button <strong>"Select user "</strong> to add them to the User Cards printing list. You can do several searches, without missing the previous selection. Once you are satisfied with the selection, press the button <strong>"print user cards "</strong>. You can select the position of the first user card in the label page.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 13:41:48.22945	1	f
en-US	cataloging.database.trash	Recycle "trash" bin	2014-07-26 10:56:18.338867	1	2014-07-26 13:41:48.22945	1	f
en-US	administration.reports.page_help	<p>The Reports routine allows to create and print several reports made available by Biblivre. Reports available are Split among the Acquisition, Cataloging and Circulation routines.</p>\n<p>Some of the reports available have filters, such as Bibliographic Base, or Term, for example. For others, you just have to select the report and press "Generate Report" ".</p>	2014-07-26 10:56:18.338867	1	2014-07-26 13:41:48.22945	1	f
en-US	circulation.user.confirm_delete_record_question.inactive	Do you really wish to mark this user as "inactive "?	2014-07-26 10:56:18.338867	1	2014-07-26 13:41:48.22945	1	f
en-US	administration.accesscards.page_help	<p>Routine for Access Cards allows registration and search of Cards used by Access control routines. Biblivre offers two registration options:</p>\n<ul><li>Register New Card: Use just one access card;</li><li>To Register Card Sequence: use more than just one access card in sequence. Use the field "pre-visualization' to see how card will be numbered.</li></ul>\n<p>When accessing this routine, Biblivre will automatically list all the Access Cards previously registered. You may then filter that list, inserting the <em>Code</em> of the Access Card you wish to find.</p>	2014-07-26 10:56:18.338867	1	2014-07-26 13:41:48.22945	1	f
en-US	acquisition.supplier.confirm_delete_record.trash	It will be moved to the "trash" database	2014-07-26 10:56:18.338867	1	2014-07-26 13:41:48.22945	1	f
en-US	circulation.user.confirm_delete_record_title.inactive	Mark user as "inactive"	2014-07-26 10:56:18.338867	1	2014-07-26 13:41:48.22945	1	f
en-US	circulation.error.invalid_user_name	This user has a name with invalid characters (:)	2014-07-26 10:56:18.338867	1	2014-07-26 13:41:48.22945	1	f
pt-BR	circulation.error.invalid_user_name	Este usuário possui nome com caracteres inválidos (:)	2014-07-26 10:56:18.338867	1	2014-07-26 13:41:48.22945	1	f
es	circulation.error.invalid_user_name	Este usuario posee un nombre con caracteres inválidos (:)	2014-07-26 10:56:18.338867	1	2014-07-26 13:41:48.22945	1	f
pt-BR	administration.reports.title.custom_count	Relatório de contagem pelo campo Marc	2014-05-21 21:47:27.923	1	2022-12-04 11:05:55.358557	0	f
pt-BR	cataloging.bibliographic.search.holding_accession_number	Tombo patrimonial	2022-12-04 11:05:55.363605	0	2022-12-04 11:05:55.363605	0	f
pt-BR	cataloging.bibliographic.search.holding_id	Código de barras da etiqueta	2022-12-04 11:05:55.365089	0	2022-12-04 11:05:55.365089	0	f
pt-BR	search.holding.shelf_location	Localização	2022-12-04 11:05:55.366132	0	2022-12-04 11:05:55.366132	0	f
pt-BR	circulation.lending.no_holding_found	Nenhum exemplar encontrado	2022-12-04 11:05:55.366943	0	2022-12-04 11:05:55.366943	0	f
en-US	administration.reports.title.custom_count	Marc field counting report	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.368006	0	f
en-US	cataloging.bibliographic.search.holding_accession_number	Asset number	2022-12-04 11:05:55.368954	0	2022-12-04 11:05:55.368954	0	f
en-US	cataloging.bibliographic.search.holding_id	Label barcode number	2022-12-04 11:05:55.369707	0	2022-12-04 11:05:55.369707	0	f
en-US	search.holding.shelf_location	Location	2022-12-04 11:05:55.370507	0	2022-12-04 11:05:55.370507	0	f
en-US	circulation.lending.no_holding_found	No copy found	2022-12-04 11:05:55.37155	0	2022-12-04 11:05:55.37155	0	f
es	administration.reports.title.custom_count	Informe de recuento del campo Marc	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.372288	0	f
es	cataloging.bibliographic.search.holding_accession_number	Sello patrimonial	2022-12-04 11:05:55.372965	0	2022-12-04 11:05:55.372965	0	f
es	cataloging.bibliographic.search.holding_id	Código de barras de la etiqueta	2022-12-04 11:05:55.373683	0	2022-12-04 11:05:55.373683	0	f
es	search.holding.shelf_location	Localización	2022-12-04 11:05:55.374112	0	2022-12-04 11:05:55.374112	0	f
es	circulation.lending.no_holding_found	Ningún ejemplar encontrado	2022-12-04 11:05:55.374585	0	2022-12-04 11:05:55.374585	0	f
pt-BR	administration.setup.biblivre4restore.skip	Ignorar	2022-12-04 11:05:55.39173	0	2022-12-04 11:05:55.39173	0	f
en-US	administration.setup.biblivre4restore.skip	Skip	2022-12-04 11:05:55.392991	0	2022-12-04 11:05:55.392991	0	f
es	administration.setup.biblivre4restore.skip	Pasar	2022-12-04 11:05:55.393954	0	2022-12-04 11:05:55.393954	0	f
pt-BR	administration.setup.biblivre4restore.error.digital_media_only_selected	O Backup selecionado contém apenas arquivos digitais. Tente novamente usando um backup completo ou parcial sem arquivos digitais	2022-12-04 11:05:55.394779	0	2022-12-04 11:05:55.394779	0	f
en-US	administration.setup.biblivre4restore.error.digital_media_only_selected	The selected Backup is a Digital Media Only file.  Try again using a Complete backup file or one without Digital Media	2022-12-04 11:05:55.395566	0	2022-12-04 11:05:55.395566	0	f
en-US	administration.setup.biblivre4restore.error.digital_media_only_should_be_selected	The second file selected is not a Digital Media Only file	2022-12-04 11:05:55.398242	0	2022-12-04 11:05:55.398242	0	f
es	administration.setup.biblivre4restore.error.digital_media_only_should_be_selected	El segundo archivo que seleccionó no  contiene sólo archivos digitales	2022-12-04 11:05:55.399074	0	2022-12-04 11:05:55.399074	0	f
pt-BR	administration.setup.biblivre4restore.select_digital_media	Selecione um Backup de Mídias Digitais	2022-12-04 11:05:55.399843	0	2022-12-04 11:05:55.399843	0	f
en-US	administration.setup.biblivre4restore.select_digital_media	Select a Digital Media Backup file	2022-12-04 11:05:55.400541	0	2022-12-04 11:05:55.400541	0	f
es	administration.setup.biblivre4restore.select_digital_media	Seleccione una copia de seguridad de archivos digitales	2022-12-04 11:05:55.401396	0	2022-12-04 11:05:55.401396	0	f
pt-BR	administration.setup.biblivre4restore.select_digital_media.description	O arquivo de backup selecionado anteriormente não possui Mídias Digitais.  Caso você possua um backup somente de Mídias Digitais, selecione abaixo o arquivo desejado, ou faça o upload do mesmo. Caso não deseje importar Mídias Digitais, clique no botão <strong>Ignorar</strong>.	2022-12-04 11:05:55.4021	0	2022-12-04 11:05:55.4021	0	f
en-US	administration.setup.biblivre4restore.select_digital_media.description	The previously selected Backup file doesn't have any Digital Media. If you have a Digital Media Only backup, select the desired one below, or upload the Digital Media Only backup file. If you don't want to import Digital Media, click on <strong>Skip</strong>.	2022-12-04 11:05:55.402947	0	2022-12-04 11:05:55.402947	0	f
es	administration.setup.biblivre4restore.select_digital_media.description	El archivo de copia de seguridad seleccionado previamente no contiene archivos digitales. Si usted tiene una copia de seguridad de sólo archivos digitales, seleccione el archivo que desee a continuación, o cargar el mismo. Si no desea importar Digital Media, haga clic en <strong>Pasar</ strong>.	2022-12-04 11:05:55.403667	0	2022-12-04 11:05:55.403667	0	f
pt-BR	multi_schema.manage.drop_schema.confirm_title	Excluir biblioteca	2022-12-04 11:05:55.404259	0	2022-12-04 11:05:55.404259	0	f
en-US	multi_schema.manage.drop_schema.confirm_title	Delete library	2022-12-04 11:05:55.404776	0	2022-12-04 11:05:55.404776	0	f
es	multi_schema.manage.drop_schema.confirm_title	Excluir biblioteca	2022-12-04 11:05:55.405316	0	2022-12-04 11:05:55.405316	0	f
pt-BR	multi_schema.manage.drop_schema.confirm_description	Você realmente deseja excluir esta biblioteca?	2022-12-04 11:05:55.405835	0	2022-12-04 11:05:55.405835	0	f
en-US	multi_schema.manage.drop_schema.confirm_description	Do you really want to delete this library?	2022-12-04 11:05:55.406264	0	2022-12-04 11:05:55.406264	0	f
es	multi_schema.manage.drop_schema.confirm_description	¿Usted realmente desea excluir esta biblioteca?	2022-12-04 11:05:55.406743	0	2022-12-04 11:05:55.406743	0	f
pt-BR	multi_schema.manage.drop_schema.confirm	Ela será excluída permanentemente do sistema e não poderá ser recuperada	2022-12-04 11:05:55.407211	0	2022-12-04 11:05:55.407211	0	f
en-US	multi_schema.manage.drop_schema.confirm	It will be deleted from the system forever and cannot be restored	2022-12-04 11:05:55.407761	0	2022-12-04 11:05:55.407761	0	f
es	multi_schema.manage.drop_schema.confirm	La biblioteca será excluida permanentemente del sistema y no podrá ser recuperada	2022-12-04 11:05:55.40834	0	2022-12-04 11:05:55.40834	0	f
pt-BR	multi_schema.backup.display_and_select_libraries	Exibir e selecionar bibliotecas {min} a {max}	2022-12-04 11:05:55.41155	0	2022-12-04 11:05:55.41155	0	f
en-US	multi_schema.backup.display_and_select_libraries	Show and select libraries from {min} to {max}	2022-12-04 11:05:55.412524	0	2022-12-04 11:05:55.412524	0	f
es	multi_schema.backup.display_and_select_libraries	Ver y seleccionar las bibliotecas de {min} a {max}	2022-12-04 11:05:55.413304	0	2022-12-04 11:05:55.413304	0	f
pt-BR	multi_schema.restore.limit.title	Bibliotecas no arquivo selecionado	2022-12-04 11:05:55.418724	0	2022-12-04 11:05:55.418724	0	f
en-US	multi_schema.restore.limit.title	Libraries in the selected file	2022-12-04 11:05:55.41928	0	2022-12-04 11:05:55.41928	0	f
es	multi_schema.restore.limit.title	Bibliotecas en el archivo seleccionado	2022-12-04 11:05:55.419784	0	2022-12-04 11:05:55.419784	0	f
pt-BR	multi_schema.restore.limit.description	O arquivo selecionado possui um número muito grande de bibliotecas. Por limites do banco de dados, a restauração deverá ser feita em passos, de no máximo 20 bibliotecas por passo. Clique nos links abaixo para listar as bibliotecas desejadas, e selecione as bibliotecas que serão restauradas. Repita esse procedimento até que todas as bibliotecas desejadas tenham sido restauradas.	2022-12-04 11:05:55.420268	0	2022-12-04 11:05:55.420268	0	f
en-US	multi_schema.restore.limit.description	The selected file contains a high number of libraries. Due to database limitations, you should restore those libraries in steps, limited to 20 libraries in each step. Click in a link below to list the desired libraries, and select the ones you want to restore. Repeat these steps untill you've restored all the libraries you need.	2022-12-04 11:05:55.4209	0	2022-12-04 11:05:55.4209	0	f
es	multi_schema.restore.limit.description	 El archivo seleccionado tiene un gran número de bibliotecas. Debido a las limitaciones de la base de datos, la restauración debe hacerse en pasos de hasta 20 bibliotecas a paso. Haga clic en los enlaces abajo para enumerar la biblioteca que desee y seleccione las bibliotecas que se restaurarán. Repita este procedimiento hasta que se hayan restaurado todas las bibliotecas deseadas.	2022-12-04 11:05:55.421402	0	2022-12-04 11:05:55.421402	0	f
pt-BR	cataloging.bibliographic.indexing_groups.publisher	Editora	2022-12-04 11:05:55.430834	0	2022-12-04 11:05:55.430834	0	f
en-US	cataloging.bibliographic.indexing_groups.publisher	Publisher	2022-12-04 11:05:55.431559	0	2022-12-04 11:05:55.431559	0	f
es	cataloging.bibliographic.indexing_groups.publisher	Editora	2022-12-04 11:05:55.432097	0	2022-12-04 11:05:55.432097	0	f
pt-BR	cataloging.bibliographic.indexing_groups.series	Série	2022-12-04 11:05:55.432636	0	2022-12-04 11:05:55.432636	0	f
en-US	cataloging.bibliographic.indexing_groups.series	Series	2022-12-04 11:05:55.433169	0	2022-12-04 11:05:55.433169	0	f
es	cataloging.bibliographic.indexing_groups.series	Serie	2022-12-04 11:05:55.433653	0	2022-12-04 11:05:55.433653	0	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_501	Notas	2022-12-04 11:05:55.435833	0	2022-12-04 11:05:55.435833	0	f
en-US	cataloging.tab.record.custom.field_label.biblio_501	Notes	2022-12-04 11:05:55.436841	0	2022-12-04 11:05:55.436841	0	f
es	cataloging.tab.record.custom.field_label.biblio_501	Notas	2022-12-04 11:05:55.437798	0	2022-12-04 11:05:55.437798	0	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_530	Notas	2022-12-04 11:05:55.438945	0	2022-12-04 11:05:55.438945	0	f
en-US	cataloging.tab.record.custom.field_label.biblio_530	Notes	2022-12-04 11:05:55.43959	0	2022-12-04 11:05:55.43959	0	f
es	cataloging.tab.record.custom.field_label.biblio_530	Notas	2022-12-04 11:05:55.440214	0	2022-12-04 11:05:55.440214	0	f
pt-BR	cataloging.tab.record.custom.field_label.biblio_595	Notas	2022-12-04 11:05:55.440894	0	2022-12-04 11:05:55.440894	0	f
en-US	cataloging.tab.record.custom.field_label.biblio_595	Notes	2022-12-04 11:05:55.441821	0	2022-12-04 11:05:55.441821	0	f
es	cataloging.tab.record.custom.field_label.biblio_595	Notas	2022-12-04 11:05:55.442491	0	2022-12-04 11:05:55.442491	0	f
pt-BR	menu.administration_brief_customization	Personalização de Resumo Catalográfico	2022-12-04 11:05:55.446974	0	2022-12-04 11:05:55.446974	0	f
en-US	menu.administration_brief_customization	Catalographic Summary Customization	2022-12-04 11:05:55.447858	0	2022-12-04 11:05:55.447858	0	f
es	menu.administration_brief_customization	Personalización del Resumen Catalográfico	2022-12-04 11:05:55.448531	0	2022-12-04 11:05:55.448531	0	f
pt-BR	menu.administration_form_customization	Personalização de Formulário Catalográfico	2022-12-04 11:05:55.449305	0	2022-12-04 11:05:55.449305	0	f
en-US	menu.administration_form_customization	Catalographic Form Customization	2022-12-04 11:05:55.449875	0	2022-12-04 11:05:55.449875	0	f
es	menu.administration_form_customization	Personalización del Formulario Catalográfico	2022-12-04 11:05:55.450457	0	2022-12-04 11:05:55.450457	0	f
pt-BR	administration.permissions.items.administration_customization	Personalização	2022-12-04 11:05:55.451025	0	2022-12-04 11:05:55.451025	0	f
en-US	administration.permissions.items.administration_customization	Customization	2022-12-04 11:05:55.45164	0	2022-12-04 11:05:55.45164	0	f
es	administration.permissions.items.administration_customization	Personalización	2022-12-04 11:05:55.452859	0	2022-12-04 11:05:55.452859	0	f
pt-BR	administration.brief_customization.separators.space-dash-space	Espaço - hífen - espaço	2022-12-04 11:05:55.455602	0	2022-12-04 11:05:55.455602	0	f
en-US	administration.brief_customization.separators.space-dash-space	Blank - dash - blank	2022-12-04 11:05:55.456505	0	2022-12-04 11:05:55.456505	0	f
es	administration.brief_customization.separators.space-dash-space	Espacio - guión - espacio	2022-12-04 11:05:55.457219	0	2022-12-04 11:05:55.457219	0	f
pt-BR	administration.brief_customization.separators.comma-space	Vírgula - espaço	2022-12-04 11:05:55.461256	0	2022-12-04 11:05:55.461256	0	f
en-US	administration.brief_customization.separators.comma-space	Comma - blank	2022-12-04 11:05:55.462257	0	2022-12-04 11:05:55.462257	0	f
es	administration.brief_customization.separators.comma-space	Coma - espacio	2022-12-04 11:05:55.462733	0	2022-12-04 11:05:55.462733	0	f
pt-BR	administration.brief_customization.separators.dot-space	Ponto - espaço	2022-12-04 11:05:55.463161	0	2022-12-04 11:05:55.463161	0	f
en-US	administration.brief_customization.separators.dot-space	Dot - blank	2022-12-04 11:05:55.463628	0	2022-12-04 11:05:55.463628	0	f
es	administration.brief_customization.separators.dot-space	Punto - espacio	2022-12-04 11:05:55.464623	0	2022-12-04 11:05:55.464623	0	f
pt-BR	administration.brief_customization.separators.colon-space	Dois pontos - espaço	2022-12-04 11:05:55.465225	0	2022-12-04 11:05:55.465225	0	f
en-US	administration.brief_customization.separators.colon-space	Colon - blank	2022-12-04 11:05:55.465991	0	2022-12-04 11:05:55.465991	0	f
es	administration.brief_customization.separators.colon-space	Dos Puntos - espacio	2022-12-04 11:05:55.466921	0	2022-12-04 11:05:55.466921	0	f
pt-BR	administration.brief_customization.separators.semicolon-space	Ponto e vírgula - espaço	2022-12-04 11:05:55.467802	0	2022-12-04 11:05:55.467802	0	f
en-US	administration.brief_customization.separators.semicolon-space	Semicolon - blank	2022-12-04 11:05:55.468809	0	2022-12-04 11:05:55.468809	0	f
es	administration.brief_customization.separators.semicolon-space	Punto y coma - espacio	2022-12-04 11:05:55.469984	0	2022-12-04 11:05:55.469984	0	f
pt-BR	administration.brief_customization.aggregators.left-parenthesis	Abre parênteses	2022-12-04 11:05:55.470894	0	2022-12-04 11:05:55.470894	0	f
en-US	administration.brief_customization.aggregators.left-parenthesis	Left parenthesis	2022-12-04 11:05:55.47172	0	2022-12-04 11:05:55.47172	0	f
es	administration.brief_customization.aggregators.left-parenthesis	Paréntesis izquierdo	2022-12-04 11:05:55.472406	0	2022-12-04 11:05:55.472406	0	f
pt-BR	administration.brief_customization.aggregators.right-parenthesis	Fecha parênteses	2022-12-04 11:05:55.473076	0	2022-12-04 11:05:55.473076	0	f
en-US	administration.brief_customization.aggregators.right-parenthesis	Right parenthesis	2022-12-04 11:05:55.473608	0	2022-12-04 11:05:55.473608	0	f
es	administration.brief_customization.aggregators.right-parenthesis	Paréntesis derecho	2022-12-04 11:05:55.474109	0	2022-12-04 11:05:55.474109	0	f
pt-BR	administration.brief_customization.confirm_disable_datafield_title	Desabilitar a exibição	2022-12-04 11:05:55.474562	0	2022-12-04 11:05:55.474562	0	f
en-US	administration.brief_customization.confirm_disable_datafield_title	Hide field	2022-12-04 11:05:55.475068	0	2022-12-04 11:05:55.475068	0	f
es	administration.brief_customization.confirm_disable_datafield_title	Ocultar campo	2022-12-04 11:05:55.475833	0	2022-12-04 11:05:55.475833	0	f
pt-BR	administration.brief_customization.confirm_disable_datafield_question	Marcando esta opção você estará escondendo o campo na aba de Resumo Catalográfico. Você poderá exibir o mesmo novamente depois, caso mude de idéia.	2022-12-04 11:05:55.476654	0	2022-12-04 11:05:55.476654	0	f
en-US	administration.brief_customization.confirm_disable_datafield_question	By selecting this option, you'll be hiding the Field from the Catalographic Summary tab. You'll be able to show the field back if you change your mind.	2022-12-04 11:05:55.477461	0	2022-12-04 11:05:55.477461	0	f
es	administration.brief_customization.confirm_disable_datafield_question	Al activar esta opción se esconden el campo en lo Resumen Catalográfico. Usted será capaz de mostrar el campo de vuelta si cambia de opinión.	2022-12-04 11:05:55.478	0	2022-12-04 11:05:55.478	0	f
pt-BR	administration.brief_customization.confirm_disable_datafield_confirm	Tem certeza que deseja remover este campo do Resumo Catalográfico?	2022-12-04 11:05:55.47844	0	2022-12-04 11:05:55.47844	0	f
en-US	administration.brief_customization.confirm_disable_datafield_confirm	Are you sure you want to hide this field from the Catalographic Summary tab?	2022-12-04 11:05:55.478962	0	2022-12-04 11:05:55.478962	0	f
es	administration.brief_customization.confirm_disable_datafield_confirm	¿Seguro que quieres ocultar este campo desde lo Resumen Catalográfico?	2022-12-04 11:05:55.479622	0	2022-12-04 11:05:55.479622	0	f
pt-BR	administration.brief_customization.page_help	<p>A rotina de Personalizaçao de Resumo Catalográfico permite configurar quais campos e subcampos MARC serão apresentados nas rotinas de Catalogação Bibliográfica, de Autoridades e de Vocabulários.  Os campos e subcampos configurados aqui serão apresentados na aba de Resumo Catalográfico nas rotinas de Catalogação. Você poderá configurar a ordem dos campos e subcampos, assim como os separadores que irão aparecer entre os subcampos.</p><p>Os campos exibidos nesta tela são os campos disponíveis no Formulário Catalográfico. Para criar novos campos, ou alterar seus subcampos, utilize a tela de <b>Personalização de Formulário Catalográfico.</b></p>	2022-12-04 11:05:55.480318	0	2022-12-04 11:05:55.480318	0	f
en-US	administration.brief_customization.page_help	<p>The Catalographic Summary Customization page lets you customize which MARC Tags and Subfields will be displayed in the Cataloging pages. The Tags and Subfields customized in this page will be displayed in the Catalographic Summary tabs in the Cataloging pages. You can customize the order for the Tags and Subfields, and also customize the separators or aggregators for the Subfields.</p><p>All the Tags and Subfields displayed here are the ones available in the Catalographic Form page. To create new Tags or Subfields, go to the <b>Catalographic Form Customization</b> page.</p>	2022-12-04 11:05:55.480955	0	2022-12-04 11:05:55.480955	0	f
es	administration.brief_customization.page_help	<p>La página Personalización de lo Resumen Catalográfico le permite personalizar cual Campos y Subcampos MARC se mostrarán en las páginas de Catalogación. Los Campos y Subcampos personalizados en esta página se mostrarán en las fichas de lo Resumen catalográfico en las páginas de Catalogación. Usted puede personalizar el orden de los Campos y Subcampos, y también personalizar los separadores o agregadores del subcampos.</p><p>Todas los Campos y Subcampos que se muestra aquí son los que están disponibles en la página de Formulario Catalográfico. Para crear nuevas etiquetas o subcampos, vaya a la <b>Personalización del Formulario Catalográfico</b>.</p>	2022-12-04 11:05:55.48153	0	2022-12-04 11:05:55.48153	0	f
pt-BR	administration.brief_customization.select_record_type	Selecione o Tipo de Registro	2022-12-04 11:05:55.48196	0	2022-12-04 11:05:55.48196	0	f
en-US	administration.brief_customization.select_record_type	Select the Record Type	2022-12-04 11:05:55.482455	0	2022-12-04 11:05:55.482455	0	f
es	administration.brief_customization.select_record_type	Seleccione el Tipo de Registro	2022-12-04 11:05:55.48314	0	2022-12-04 11:05:55.48314	0	f
pt-BR	administration.brief_customization.biblio	Registro Bibliográfico	2022-12-04 11:05:55.483666	0	2022-12-04 11:05:55.483666	0	f
en-US	administration.brief_customization.biblio	Bibliographic Record	2022-12-04 11:05:55.484175	0	2022-12-04 11:05:55.484175	0	f
es	administration.brief_customization.biblio	Registro Bibliográfico	2022-12-04 11:05:55.484628	0	2022-12-04 11:05:55.484628	0	f
pt-BR	administration.brief_customization.authorities	Registro de Autoridades	2022-12-04 11:05:55.485033	0	2022-12-04 11:05:55.485033	0	f
en-US	administration.brief_customization.authorities	Authorities Record	2022-12-04 11:05:55.485468	0	2022-12-04 11:05:55.485468	0	f
es	administration.brief_customization.authorities	Registro de Autoridad	2022-12-04 11:05:55.486082	0	2022-12-04 11:05:55.486082	0	f
pt-BR	administration.brief_customization.vocabulary	Registro de Vocabulário	2022-12-04 11:05:55.486549	0	2022-12-04 11:05:55.486549	0	f
en-US	administration.brief_customization.vocabulary	Vocabulary record	2022-12-04 11:05:55.486986	0	2022-12-04 11:05:55.486986	0	f
es	administration.brief_customization.vocabulary	Registro de Vocabulario	2022-12-04 11:05:55.487448	0	2022-12-04 11:05:55.487448	0	f
pt-BR	administration.brief_customization.subfields_title	Subcampos	2022-12-04 11:05:55.488062	0	2022-12-04 11:05:55.488062	0	f
en-US	administration.brief_customization.subfields_title	Subfields	2022-12-04 11:05:55.488604	0	2022-12-04 11:05:55.488604	0	f
es	administration.brief_customization.subfields_title	Subcampo	2022-12-04 11:05:55.489017	0	2022-12-04 11:05:55.489017	0	f
pt-BR	administration.brief_customization.separators_title	Separadores de subcampo	2022-12-04 11:05:55.489451	0	2022-12-04 11:05:55.489451	0	f
en-US	administration.brief_customization.separators_title	Subfield separators	2022-12-04 11:05:55.489979	0	2022-12-04 11:05:55.489979	0	f
es	administration.brief_customization.separators_title	Separadores de subcampo	2022-12-04 11:05:55.490597	0	2022-12-04 11:05:55.490597	0	f
pt-BR	administration.brief_customization.aggregators_title	Agregadores de subcampo	2022-12-04 11:05:55.491129	0	2022-12-04 11:05:55.491129	0	f
en-US	administration.brief_customization.aggregators_title	Subfield aggregators	2022-12-04 11:05:55.491699	0	2022-12-04 11:05:55.491699	0	f
es	administration.brief_customization.aggregators_title	Agregadores de subcampo	2022-12-04 11:05:55.492158	0	2022-12-04 11:05:55.492158	0	f
pt-BR	administration.form_customization.page_help	<p>A rotina de Personalização de Formulário Catalográfico permite configurar quais Campos, Subcampos e Indicadores MARC serão apresentados nas rotinas de Catalogação Bibliográfica, de Autoridades e de Vocabulários. Os Campos, Subcampos e Indicadores configurados aqui serão apresentados na aba de Formulário Catalográfico nas rotinas de Catalogação. Você poderá configurar a ordem dos Campos, Subcampos e Indicadores, assim como editar cada Campo, adicionando ou removendo Subcampos e Indicadores, ou alterando os textos dos elementos MARC.</p>	2022-12-04 11:05:55.49266	0	2022-12-04 11:05:55.49266	0	f
en-US	administration.form_customization.page_help	<p>The Catalographic Form Customization allows you to configure which MARC Tags, Subfields and Indicators will be displayed in the Cataloging pages. The Tags, Subfields and Indicators set here will be displayed in the Cataloging Form tab in the Cataloging pages. You can customize the order of the Tags, Subfields and Indicators, as well as edit each Tag by adding or removing Subfields and Indicators, or changing the text of the MARC elements.</p>	2022-12-04 11:05:55.493188	0	2022-12-04 11:05:55.493188	0	f
es	administration.form_customization.page_help	<p>La página Personalización del Formulario Catalográfico le permite configurar cual Campos, Subcampos e Indicadores MARC se mostrarán en las páginas de catalogación. Los Campos, Subcampos e Indicadores establecidos aquí se mostrarán en la pestaña Formulario Catalografico en las páginas de Catalogación. Puede personalizar el orden de los Campos, Subcampos e Indicadores, así como editar cada etiqueta mediante la adición o eliminación de Subcampos e Indicadores, o cambiando el texto de los elementos MARC.</p>	2022-12-04 11:05:55.493662	0	2022-12-04 11:05:55.493662	0	f
pt-BR	administration.form_customization.field	Campo MARC	2022-12-04 11:05:55.494084	0	2022-12-04 11:05:55.494084	0	f
en-US	administration.form_customization.field	MARC Tag	2022-12-04 11:05:55.49448	0	2022-12-04 11:05:55.49448	0	f
es	administration.form_customization.field	Campo MARC	2022-12-04 11:05:55.49483	0	2022-12-04 11:05:55.49483	0	f
pt-BR	administration.form_customization.field_name	Nome do Campo	2022-12-04 11:05:55.495272	0	2022-12-04 11:05:55.495272	0	f
en-US	administration.form_customization.field_name	Tag Name	2022-12-04 11:05:55.49571	0	2022-12-04 11:05:55.49571	0	f
es	administration.form_customization.field_name	Nombre del Campo	2022-12-04 11:05:55.496093	0	2022-12-04 11:05:55.496093	0	f
pt-BR	administration.form_customization.field_repeatable	Repetível	2022-12-04 11:05:55.496513	0	2022-12-04 11:05:55.496513	0	f
en-US	administration.form_customization.field_repeatable	Repeatable	2022-12-04 11:05:55.496883	0	2022-12-04 11:05:55.496883	0	f
es	administration.form_customization.field_repeatable	Repetible	2022-12-04 11:05:55.497241	0	2022-12-04 11:05:55.497241	0	f
pt-BR	administration.form_customization.field_collapsed	Colapsado	2022-12-04 11:05:55.497617	0	2022-12-04 11:05:55.497617	0	f
en-US	administration.form_customization.field_collapsed	Collapsed	2022-12-04 11:05:55.497998	0	2022-12-04 11:05:55.497998	0	f
es	administration.form_customization.field_collapsed	Colapsado	2022-12-04 11:05:55.498541	0	2022-12-04 11:05:55.498541	0	f
pt-BR	administration.form_customization.indicator_number	Indicador	2022-12-04 11:05:55.499136	0	2022-12-04 11:05:55.499136	0	f
en-US	administration.form_customization.indicator_number	Indicator	2022-12-04 11:05:55.499838	0	2022-12-04 11:05:55.499838	0	f
es	administration.form_customization.indicator_number	Indicador	2022-12-04 11:05:55.500618	0	2022-12-04 11:05:55.500618	0	f
pt-BR	administration.form_customization.indicator_name	Nome do indicador	2022-12-04 11:05:55.501542	0	2022-12-04 11:05:55.501542	0	f
en-US	administration.form_customization.indicator_name	Indicator name	2022-12-04 11:05:55.502271	0	2022-12-04 11:05:55.502271	0	f
es	administration.form_customization.indicator_name	Nombre del indicador	2022-12-04 11:05:55.503063	0	2022-12-04 11:05:55.503063	0	f
pt-BR	administration.form_customization.indicator_values	Valores	2022-12-04 11:05:55.503862	0	2022-12-04 11:05:55.503862	0	f
en-US	administration.form_customization.indicator_values	Values	2022-12-04 11:05:55.504431	0	2022-12-04 11:05:55.504431	0	f
es	administration.form_customization.indicator_values	Valores	2022-12-04 11:05:55.505048	0	2022-12-04 11:05:55.505048	0	f
pt-BR	administration.form_customization.change_indicators	Alterar	2022-12-04 11:05:55.505632	0	2022-12-04 11:05:55.505632	0	f
en-US	administration.form_customization.change_indicators	Change	2022-12-04 11:05:55.506014	0	2022-12-04 11:05:55.506014	0	f
es	administration.form_customization.change_indicators	Cambio	2022-12-04 11:05:55.506389	0	2022-12-04 11:05:55.506389	0	f
pt-BR	administration.form_customization.material_type	Tipos de Material	2022-12-04 11:05:55.506785	0	2022-12-04 11:05:55.506785	0	f
en-US	administration.form_customization.material_type	Material Type	2022-12-04 11:05:55.507341	0	2022-12-04 11:05:55.507341	0	f
es	administration.form_customization.material_type	Tipos de Material	2022-12-04 11:05:55.507941	0	2022-12-04 11:05:55.507941	0	f
pt-BR	administration.form_customization.subfield	MARC	2022-12-04 11:05:55.508405	0	2022-12-04 11:05:55.508405	0	f
en-US	administration.form_customization.subfield	MARC	2022-12-04 11:05:55.508864	0	2022-12-04 11:05:55.508864	0	f
es	administration.form_customization.subfield	MARC	2022-12-04 11:05:55.509304	0	2022-12-04 11:05:55.509304	0	f
pt-BR	administration.form_customization.subfield_name	Nome do Subcampo	2022-12-04 11:05:55.509773	0	2022-12-04 11:05:55.509773	0	f
en-US	administration.form_customization.subfield_name	Subfield name	2022-12-04 11:05:55.510301	0	2022-12-04 11:05:55.510301	0	f
es	administration.form_customization.subfield_name	Nombre del Subcampo	2022-12-04 11:05:55.510821	0	2022-12-04 11:05:55.510821	0	f
pt-BR	administration.form_customization.subfield_repeatable	Repetível	2022-12-04 11:05:55.511237	0	2022-12-04 11:05:55.511237	0	f
en-US	administration.form_customization.subfield_repeatable	Repeatable	2022-12-04 11:05:55.511631	0	2022-12-04 11:05:55.511631	0	f
es	administration.form_customization.subfield_repeatable	Repetible	2022-12-04 11:05:55.512111	0	2022-12-04 11:05:55.512111	0	f
pt-BR	administration.form_customization.subfield_collapsed	Oculto	2022-12-04 11:05:55.512888	0	2022-12-04 11:05:55.512888	0	f
en-US	administration.form_customization.subfield_collapsed	Hidden	2022-12-04 11:05:55.513385	0	2022-12-04 11:05:55.513385	0	f
es	administration.form_customization.subfield_collapsed	Oculto	2022-12-04 11:05:55.513812	0	2022-12-04 11:05:55.513812	0	f
pt-BR	administration.form_customization.subfield_autocomplete.label	Auto Completar	2022-12-04 11:05:55.514182	0	2022-12-04 11:05:55.514182	0	f
en-US	administration.form_customization.subfield_autocomplete.label	Autocomplete	2022-12-04 11:05:55.514558	0	2022-12-04 11:05:55.514558	0	f
es	administration.form_customization.subfield_autocomplete.label	Autocompletar	2022-12-04 11:05:55.514933	0	2022-12-04 11:05:55.514933	0	f
pt-BR	administration.form_customization.subfield_autocomplete.	Auto Completar	2022-12-04 11:05:55.515304	0	2022-12-04 11:05:55.515304	0	f
en-US	administration.form_customization.subfield_autocomplete.	Autocomplete	2022-12-04 11:05:55.515725	0	2022-12-04 11:05:55.515725	0	f
es	administration.form_customization.subfield_autocomplete.	Autocompletar	2022-12-04 11:05:55.516132	0	2022-12-04 11:05:55.516132	0	f
pt-BR	administration.form_customization.subfield_autocomplete.disabled	Desabilitado	2022-12-04 11:05:55.516538	0	2022-12-04 11:05:55.516538	0	f
en-US	administration.form_customization.subfield_autocomplete.disabled	Disabled	2022-12-04 11:05:55.516946	0	2022-12-04 11:05:55.516946	0	f
es	administration.form_customization.subfield_autocomplete.disabled	Inactivo	2022-12-04 11:05:55.517334	0	2022-12-04 11:05:55.517334	0	f
pt-BR	administration.form_customization.subfield_autocomplete.previous_values	Valores anteriores	2022-12-04 11:05:55.517811	0	2022-12-04 11:05:55.517811	0	f
en-US	administration.form_customization.subfield_autocomplete.previous_values	Previous Values	2022-12-04 11:05:55.518244	0	2022-12-04 11:05:55.518244	0	f
es	administration.form_customization.subfield_autocomplete.previous_values	Valores anteriores	2022-12-04 11:05:55.518692	0	2022-12-04 11:05:55.518692	0	f
pt-BR	administration.form_customization.subfield_autocomplete.fixed_table	Tabela fixa	2022-12-04 11:05:55.519165	0	2022-12-04 11:05:55.519165	0	f
en-US	administration.form_customization.subfield_autocomplete.fixed_table	Fixed Table	2022-12-04 11:05:55.519599	0	2022-12-04 11:05:55.519599	0	f
es	administration.form_customization.subfield_autocomplete.fixed_table	Tabla fija	2022-12-04 11:05:55.520024	0	2022-12-04 11:05:55.520024	0	f
pt-BR	administration.form_customization.subfield_autocomplete.fixed_table_with_previous_values	Tabela e Valores	2022-12-04 11:05:55.52046	0	2022-12-04 11:05:55.52046	0	f
en-US	administration.form_customization.subfield_autocomplete.fixed_table_with_previous_values	Table and Values	2022-12-04 11:05:55.520856	0	2022-12-04 11:05:55.520856	0	f
es	administration.form_customization.subfield_autocomplete.fixed_table_with_previous_values	Tabla e Valores	2022-12-04 11:05:55.521282	0	2022-12-04 11:05:55.521282	0	f
pt-BR	administration.form_customization.subfield_autocomplete.biblio	Bibliográfico	2022-12-04 11:05:55.521735	0	2022-12-04 11:05:55.521735	0	f
en-US	administration.form_customization.subfield_autocomplete.biblio	Bibliographic	2022-12-04 11:05:55.522209	0	2022-12-04 11:05:55.522209	0	f
es	administration.form_customization.subfield_autocomplete.biblio	Bibliografico	2022-12-04 11:05:55.522682	0	2022-12-04 11:05:55.522682	0	f
pt-BR	administration.form_customization.subfield_autocomplete.authorities	Autoridades	2022-12-04 11:05:55.523169	0	2022-12-04 11:05:55.523169	0	f
en-US	administration.form_customization.subfield_autocomplete.authorities	Authorities	2022-12-04 11:05:55.523604	0	2022-12-04 11:05:55.523604	0	f
es	administration.form_customization.subfield_autocomplete.authorities	Autoridades	2022-12-04 11:05:55.523959	0	2022-12-04 11:05:55.523959	0	f
pt-BR	administration.form_customization.subfield_autocomplete.vocabulary	Vocabulário	2022-12-04 11:05:55.5243	0	2022-12-04 11:05:55.5243	0	f
en-US	administration.form_customization.subfield_autocomplete.vocabulary	Vocabulary	2022-12-04 11:05:55.524692	0	2022-12-04 11:05:55.524692	0	f
es	administration.form_customization.subfield_autocomplete.vocabulary	Vocabulario	2022-12-04 11:05:55.525114	0	2022-12-04 11:05:55.525114	0	f
pt-BR	administration.translations.error.invalid_language	Idioma em branco ou desconhecido	2014-06-14 19:34:08.805257	1	2022-12-04 11:05:55.525473	0	f
en-US	administration.translations.error.invalid_language	The "language_code" field is mandatory	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.526136	0	f
es	administration.translations.error.invalid_language	El campo "language_code" es obligatorio	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.526752	0	f
pt-BR	administration.form_customization.subfields	Subcampos	2022-12-04 11:05:55.527501	0	2022-12-04 11:05:55.527501	0	f
en-US	administration.form_customization.subfields	Subfields	2022-12-04 11:05:55.527963	0	2022-12-04 11:05:55.527963	0	f
es	administration.form_customization.subfields	Subcampos	2022-12-04 11:05:55.52842	0	2022-12-04 11:05:55.52842	0	f
pt-BR	administration.translations.save	Salvar traduções	2022-12-04 11:05:55.528838	0	2022-12-04 11:05:55.528838	0	f
en-US	administration.translations.save	Save translations	2022-12-04 11:05:55.529208	0	2022-12-04 11:05:55.529208	0	f
es	administration.translations.save	Guardar traducciones	2022-12-04 11:05:55.529544	0	2022-12-04 11:05:55.529544	0	f
pt-BR	administration.translations.edit.title	Editar traduções	2022-12-04 11:05:55.529961	0	2022-12-04 11:05:55.529961	0	f
en-US	administration.translations.edit.title	Edit translations	2022-12-04 11:05:55.530356	0	2022-12-04 11:05:55.530356	0	f
es	administration.translations.edit.title	Editar traducciones	2022-12-04 11:05:55.530785	0	2022-12-04 11:05:55.530785	0	f
pt-BR	administration.translations.edit.description	<p>Abaixo você pode editar as traduções sem ter que baixar o arquivo. Esta tela é ideal para rápidas alterações em textos do Biblivre. O idioma exibido abaixo é o mesmo que está atualmente em uso. Para editar as traduções de outro idioma, troque o idioma atual do Biblivre por outro no topo da página. Caso você tenha personalizado seu Biblivre na tela de Personalizacao, você precisará ajustar os nomes dos campos criados para todos os idiomas instalados. Para facilitar nesse trabalho, clique na caixa "Exibir apenas os campos sem tradução".</p><p>Você pode também adicionar um novo idioma diretamente nesta tela. Para tanto, basta alterar o valor do campo "language_code".</p>	2022-12-04 11:05:55.531143	0	2022-12-04 11:05:55.531143	0	f
en-US	administration.translations.edit.description	<p>Below you can edit the translations without downloading the translations file. This screen is ideal for rapid changes in Biblivre texts. The language displayed below is the same as the one currently in use. To edit translations from another language, change the current language at the top of the page. If you have customized your Biblivre in the Customization screen, you need to adjust the field names created for all languages installed. To facilitate this work, click the box "Display only untranslated fields".</p><p>You can also add a new language directly on this screen. To do so, just change the value of the "language_code" field.</p>	2022-12-04 11:05:55.531648	0	2022-12-04 11:05:55.531648	0	f
es	administration.translations.edit.description	<p>A continuación puede editar las traducciones sin tener que descargar el archivo. Esta pantalla es ideal para los rápidos cambios en los textos Biblivre. El idioma que se muestra a continuación es la misma que está actualmente en uso. Para editar las traducciones de otro idioma, cambie el idioma en la parte superior de la página. Si ha personalizado su Biblivre en la pantalla de Personalización, es necesario ajustar los nombres de los campos creados para todos los idiomas instalados. Para facilitar este trabajo, haga click en la casilla "Mostrar sólo los campos sin traducir". </p><p>También puede añadir un nuevo idioma directamente en esta pantalla. Para ello, basta cambiar el valor del campo "language_code".</p>	2022-12-04 11:05:55.532223	0	2022-12-04 11:05:55.532223	0	f
pt-BR	administration.translations.edit.filter	Exibir apenas os campos sem tradução	2022-12-04 11:05:55.532709	0	2022-12-04 11:05:55.532709	0	f
en-US	administration.translations.edit.filter	Display only untranslated fields	2022-12-04 11:05:55.533102	0	2022-12-04 11:05:55.533102	0	f
es	administration.translations.edit.filter	Mostrar sólo los campos sin traducir	2022-12-04 11:05:55.533538	0	2022-12-04 11:05:55.533538	0	f
pt-BR	administration.brief_customization.available_fields.description	Os campos abaixo estão configurados no Formulário Catalográfico, porém não serão exibidos no Resumo Catalográfico.	2022-12-04 11:05:55.533983	0	2022-12-04 11:05:55.533983	0	f
en-US	administration.brief_customization.available_fields.description	Save translations	2022-12-04 11:05:55.534385	0	2022-12-04 11:05:55.534385	0	f
es	administration.brief_customization.available_fields.description	Guardar traducciones	2022-12-04 11:05:55.534802	0	2022-12-04 11:05:55.534802	0	f
pt-BR	administration.form_customization.indicator.label_value	Valor	2022-12-04 11:05:55.535248	0	2022-12-04 11:05:55.535248	0	f
en-US	administration.form_customization.indicator.label_value	Value	2022-12-04 11:05:55.535687	0	2022-12-04 11:05:55.535687	0	f
es	administration.form_customization.indicator.label_value	Valor	2022-12-04 11:05:55.536141	0	2022-12-04 11:05:55.536141	0	f
pt-BR	administration.form_customization.indicator.label_text	Texto	2022-12-04 11:05:55.536661	0	2022-12-04 11:05:55.536661	0	f
en-US	administration.form_customization.indicator.label_text	Text	2022-12-04 11:05:55.537085	0	2022-12-04 11:05:55.537085	0	f
es	administration.form_customization.indicator.label_text	Texto	2022-12-04 11:05:55.537615	0	2022-12-04 11:05:55.537615	0	f
pt-BR	administration.form_customization.button_add_field	Adicionar Campo	2022-12-04 11:05:55.538098	0	2022-12-04 11:05:55.538098	0	f
en-US	administration.form_customization.button_add_field	Add Tag	2022-12-04 11:05:55.538631	0	2022-12-04 11:05:55.538631	0	f
es	administration.form_customization.button_add_field	Agregar Campo	2022-12-04 11:05:55.539191	0	2022-12-04 11:05:55.539191	0	f
pt-BR	administration.form_customization.error.existing_tag	Já existe um Campo com esta tag.	2022-12-04 11:05:55.539645	0	2022-12-04 11:05:55.539645	0	f
en-US	administration.form_customization.error.existing_tag	Tag already exists.	2022-12-04 11:05:55.539991	0	2022-12-04 11:05:55.539991	0	f
es	administration.form_customization.error.existing_tag	Campo ya existe.	2022-12-04 11:05:55.540315	0	2022-12-04 11:05:55.540315	0	f
pt-BR	administration.form_customization.error.existing_subfield	Já existe um Subcampo com esta tag.	2022-12-04 11:05:55.540795	0	2022-12-04 11:05:55.540795	0	f
en-US	administration.form_customization.error.existing_subfield	Subfield already exists.	2022-12-04 11:05:55.541175	0	2022-12-04 11:05:55.541175	0	f
es	administration.form_customization.error.existing_subfield	Subcampo ya existe.	2022-12-04 11:05:55.541539	0	2022-12-04 11:05:55.541539	0	f
pt-BR	administration.form_customization.confirm_delete_datafield_title	Excluir Campo	2022-12-04 11:05:55.541895	0	2022-12-04 11:05:55.541895	0	f
en-US	administration.form_customization.confirm_delete_datafield_title	Delete Datafield	2022-12-04 11:05:55.542405	0	2022-12-04 11:05:55.542405	0	f
es	administration.form_customization.confirm_delete_datafield_title	Excluir Campo	2022-12-04 11:05:55.54277	0	2022-12-04 11:05:55.54277	0	f
pt-BR	administration.form_customization.confirm_delete_datafield_description	Você realmente deseja excluir este campo? Esta operação é irreversível, e o campo só será apresentado na aba Marc.	2022-12-04 11:05:55.543116	0	2022-12-04 11:05:55.543116	0	f
en-US	administration.form_customization.confirm_delete_datafield_description	Do you really wish to delete this datafield? This operation cannot be undone, and the field will be displayed only on Marc tab.	2022-12-04 11:05:55.543456	0	2022-12-04 11:05:55.543456	0	f
es	administration.form_customization.confirm_delete_datafield_description	¿Usted realmente desea excluir este campo? Esta operación es irreversible, y el campo sólo se mostrará en la pestaña Marc.	2022-12-04 11:05:55.543802	0	2022-12-04 11:05:55.543802	0	f
pt-BR	administration.form_customization.error.invalid_tag	Campo Marc inválido. O campo Marc deve ser numérico, e possuir 3 digitos.	2022-12-04 11:05:55.544141	0	2022-12-04 11:05:55.544141	0	f
en-US	administration.form_customization.error.invalid_tag	Invalid Datafield Tag. The datafield Tag should be a 3 digits number.	2022-12-04 11:05:55.544488	0	2022-12-04 11:05:55.544488	0	f
es	administration.form_customization.error.invalid_tag	Campo Marc inválido. El campo Marc debe ser numérico con 3 dígitos.	2022-12-04 11:05:55.544869	0	2022-12-04 11:05:55.544869	0	f
pt-BR	multi_schema.configuration.description.general.title	Nomo que será exibido quando a página principal deste grupo de bibliotecas for acessada. Esta página listará todas as bibliotecas cadastradas neste grupo (gerenciadas pelo mesmo BIBLIVRE 5).	2014-06-21 11:54:49.572182	1	2022-12-04 11:05:55.5474	1	f
es	administration.configuration.description.multi_schema.enabled	El sistema de multi-bibliotecas ya está habilitado para esta instalación del BIBLIVRE 5. El administrador del sistema podrá deshabilitar esa opción en el menú de configuración de multibibliotecas.	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
pt-BR	multi_schema.translations.page_help	<p>O módulo de <strong>"Traduções"</strong> de Multi-bibliotecas funciona de forma análoga a sua versão de uma única biblioteca, porém, textos alterados por aqui serão aplicados a todas as bibliotecas do grupo, desde que estas não tenham alterado o valor original de cada tradução.</p>\n<p>Por exemplo, se você alterar a tradução da chave <strong>"menu.search"</strong> de "Pesquisa" para "Busca" pelo módulo de traduções multi-bibliotecas, todas as bibliotecas deste grupo verão a nova tradução. Porém, se um dos administradores de uma destas bibliotecas alterar, através do módulo de <strong>"Traduções"</strong> de sua biblioteca, a mesma chave para "Procurar", esta tradução interna terá prioridade, apenas para esta biblioteca.</p>\n<p>Para adicionar um novo idioma, baixe o arquivo de idioma em Português, faça a tradução dos textos e depois faça o envio do arquivo. Lembre-se que apenas os <strong>textos</strong> (depois do sinal de igual) devem ser alterados.  Não altere as chaves, ou o BIBLIVRE 5 não conseguirá localizar o texto</p>\n<p>Exemplo: digamos que você queira alterar o texto no menu principal de <i>Pesquisa</i> para <i>Busca</i>.  Você deverá então baixar o arquivo do idioma e alterar a seguinte linha:</p>\n<p><strong>*menu.search</strong> = Pesquisa</p>\n<p>Para:</p>\n<p><strong>*menu.search</strong> = Busca</p>\n<p>E então fazer o Envio do arquivo de idiomas. O BIBLIVRE 5 irá processar o arquivo, e alterar o texto do menu.</p>	2014-06-21 11:54:49.572182	1	2022-12-04 11:05:55.5474	1	f
pt-BR	multi_schema.configuration.description.general.subtitle	Subtítulo que será exibido quando a página principal deste grupo de bibliotecas for acessada. Esta página listará todas as bibliotecas cadastradas neste grupo (gerenciadas pelo mesmo BIBLIVRE 5).	2014-06-21 11:54:49.572182	1	2022-12-04 11:05:55.5474	1	f
pt-BR	warning.new_version	Já está disponível uma atualização para o BIBLIVRE 5<br/>Versão instalada: {0}. Versão mais recente: {1}	2014-07-05 11:47:02.155561	1	2022-12-04 11:05:55.5474	1	f
pt-BR	multi_schema.manage.page_help	A tela de multi-bibliotecas permite cadastrar diversas bibliotecas para serem gerenciadas por um único Biblivre. A partir do momento que você habilitar o sistema de multi-bibliotecas, a lista de bibliotecas cadastradas será exibida sempre que alguém entrar no endereço padrão do BIBLIVRE 5.	2014-06-14 19:50:04.110972	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.maintenance.reinstall.confirm.description	Deseja ir para a tela de restauração e reconfiguração? Você poderá restaurar um backup do BIBLIVRE 5, apagar os dados da sua biblioteca ou refazer uma migração.	2014-06-21 14:25:12.053902	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.setup.cancel.description	Clique no botão abaixo para desistir de restaurar esta instalação do BIBLIVRE 5 e retornar à sua biblioteca.	2014-06-21 14:25:12.053902	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.maintenance.reinstall.description	Use esta opção caso você queira restaurar um backup do BIBLIVRE 5, apagar os dados da sua biblioteca ou refazer a migração do Biblivre 3. Você será enviado à tela inicial de instalação do Biblivre, onde poderá cancelar caso desista de fazer alterações.	2014-06-21 14:25:12.053902	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.configuration.description.logged_out_text	Texto que será exibido na tela inicial do Biblivre, para usuários que não tenham entrado com login e senha. Você pode usar tags HTML, mas cuidado para não quebrar o layout do BIBLIVRE 5. Atenção: esta configuração está relacionada com o sistema de traduções. Alterações feitas nesta tela afetarão somente o idioma atual. Para alterar em outros idiomas, use a tela de traduções ou acesse o Biblivre usando o idioma a ser alterado.	2014-07-12 11:21:42.419959	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.configuration.description.logged_in_text	Texto que será exibido na tela inicial do Biblivre, para usuários que tenham entrado com login e senha. Você pode usar tags HTML, mas cuidado para não quebrar o layout do BIBLIVRE 5. O termo {0} será substituído pelo nome do usuário logado. Atenção: esta configuração está relacionada com o sistema de traduções. Alterações feitas nesta tela afetarão somente o idioma atual. Para alterar em outros idiomas, use a tela de traduções ou acesse o Biblivre usando o idioma a ser alterado.	2014-07-12 11:21:42.419959	1	2022-12-04 11:05:55.5474	1	f
pt-BR	multi_schema.manage.new_schema.description	Para criar uma nova biblioteca, preencha abaixo seu nome e um subtítulo opcional. Você também precisará de um nome reduzido para a biblioteca, chamado de atalho, que será usado no endereço Web de acesso ao BIBLIVRE 5, permitindo diferenciar as diversas bibliotecas instaladas no sistema. Este atalho deve conter apenas letras, números e o caractere _. Para facilitar, o BIBLIVRE 5 irá sugerir um atalho automaticamente, baseado no nome da biblioteca.	2014-06-14 19:50:04.110972	1	2022-12-04 11:05:55.5474	1	f
pt-BR	multi_schema.manage.schemas.description	Abaixo estão todas as bibliotecas cadastradas neste BIBLIVRE 5. Caso queira alterar um nome ou subtítulo, acesse a tela de configurações da biblioteca.	2014-06-14 19:50:04.110972	1	2022-12-04 11:05:55.5474	1	f
es	administration.setup.biblivre4restore.error.description	Lamentablemente ocurrió un error al restaurar este backup de BIBLIVRE 5. Verifique la próxima pantalla por el log de errores y, en caso necesario, entre en el fórum Biblivre para obtener ayuda.	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	administration.maintenance.backup.description.3	El Backup sin archivos digitales es una copia de todos los datos e informaciones del BIBLIVRE 5, <strong>excluyendo</strong> los archivos de medio digital. Por excluir los archivos de medio digital, el proceso tanto de backup cuanto de recuperación es más rápido, y el archivo de backup es menor.	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	administration.maintenance.backup.description.1	El Backup es un proceso donde ejecutamos la copia de informaciones para guardarlas en caso de algún problema en el sistema. Es una copia de los registros e informaciones del Biblivre. El BIBLIVRE 5 posee 3 tipos de backup:	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	administration.maintenance.backup.description.2	El Backup completo es una copia de todos los datos e informaciones del BIBLIVRE 5, incluyendo los archivos de medio digital, como fotos de los usuarios, archivos digitales de los registros bibliográficos, etc.	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	administration.migration.page_help	<p>El módulo de <strong>"Migración de Datos"</strong> permite importar los datos que están en una base de datos del Biblivre 3 existente para la base de datos vacía del BIBLIVRE 5.</p>	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	administration.configuration.description.logged_out_text	Texto a ser exhibido en la pantalla del Biblivre, para usuarios que no tengan ingresado con login y contraseña. Usted puede utilizar tags HTML, pero cuidado de no quebrar el diseño del BIBLIVRE 5. Atención: esta configuración se relaciona con el sistema de traducciones. Las alteraciones realizadas en esta pantalla afectarán solamente el idioma actual. Para alterar en otros idiomas, utilice la pantalla de traducciones o acceda al Biblivre utilizando el idioma a ser alterado.	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	multi_schema.manage.schemas.description	Abajo están todas las bibliotecas registradas en este BIBLIVRE 5. En caso que quiera alterar un nombre o subtítulo, accese a la pantalla de configuraciones de la biblioteca.	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	administration.translations.page_help	<p>El módulo de <strong>"Traducciones"</strong> permite agregar nuevos idiomas al BIBLIVRE 5 o alterar los textos ya existentes.</p>\n<p><strong>Atención: Este módulo realiza configuraciones avanzadas del BIBLIVRE 5, y debe ser utilizado solamente por Usuarios avanzados, con experiencia en informática.</strong>.</p>\n<p>Para agregar un nuevo idioma, baje el archivo de idioma en portugués, haga la traducción de los textos y después envíe el archivo. Recuerde que solamente los <strong>textos</strong> (después del signo igual) deben ser alterados.  No altere las llaves, caso contrario el BIBLIVRE 5 no conseguirá localizar el texto</p>\n<p>Ejemplo: digamos que usted quiera alterar el texto en el menú principal de <i>Búsqueda</i> para <i>Buscar</i>.  Usted deberá entonces bajar el archivo del idioma y alterar la siguiente línea:</p>\n<p><strong>*menu.search</strong> = Búsqueda</p>\n<p>Para:</p>\n<p><strong>*menu.search</strong> = Busca</p>\n<p>Y entonces hacer el envío del archivo de idiomas. El BIBLIVRE 5 procesará el archivo, y alterará el texto del menú.</p>	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	administration.maintenance.reinstall.confirm.description	¿Desea ir a la pantalla de restauración y reconfiguración? Usted podrá restaurar un backup del BIBLIVRE 5, borrar los datos de su biblioteca o rehacer una migración.	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	administration.setup.clean_install.description	En caso que usted no tenga o no desee restaurar un backup, esta opción permitirá iniciar el uso del BIBLIVRE 5 con una base de datos vacía. Luego de entrar en el BIBLIVRE 5 por primera vez, utilice el login <strong>admin</strong> y la contraseña <strong>abracadabra</strong> para entrar al sistema y configurar su nueva biblioteca.	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	multi_schema.configuration.description.general.title	Nombre que será exhibido cuando se accede a la página principal de este grupo de bibliotecas. Esta página listará todas las bibliotecas registradas en este grupo (administradas por el mismo BIBLIVRE 5).	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	multi_schema.manage.page_help	La pantalla de multibibliotecas permite registrar diversas bibliotecas para ser administradas por un único Biblivre. A partir del momento que usted habilita el sistema de multi-bibliotecas, la lista de bibliotecas registradas será exhibida siempre que alguien entre en la dirección estándar del BIBLIVRE 5.	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	administration.configuration.description.general.multi_schema	Esta configuración permite que se habilite el sistema de múltiples bibliotecas en esta instalación del BIBLIVRE 5.	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	multi_schema.manage.log_header	[Log de creación de nueva biblioteca del BIBLIVRE 5]	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	administration.setup.cancel.description	Cliquee en el botón abajo para desistir de restaurar esta instalación del BIBLIVRE 5 y volver a su biblioteca.	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	multi_schema.manage.new_schema.description	Para crear una nueva biblioteca, rellene abajo con su nombre y un subtítulo opcional. Usted también precisará de un nombre reducido para la biblioteca, llamado de atajo, que será usado en la dirección Web de acceso al BIBLIVRE 5, permitiendo diferenciar las diversas bibliotecas instaladas en el sistema. Este atajo debe contener solamente letras, números y/o caracteres _. Para facilitar, el BIBLIVRE 5 sugerirá un atajo automáticamente, basado en el nombre de la biblioteca.	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	administration.maintenance.reinstall.description	Use esta opción en caso que usted desee restaurar un backup del BIBLIVRE 5, borrar los datos de su biblioteca o rehacer la migración del Biblivre 3. Usted será enviado a la pantalla inicial de instalación del Biblivre, donde podrá cancelar en caso que desista de hacer alteraciones.	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	administration.configuration.description.logged_in_text	Texto a ser exhibido en la pantalla inicial del Biblivre, para usuarios que tengan ingresado con login y contraseña. Usted puede utilizar tags HTML, pero cuidado de no quebrar el diseño del BIBLIVRE 5. El término {0} será sustituido por el nombre del usuario logueado. Atención: esta configuración se relaciona con el sistema de traducciones. Las alteraciones realizadas en esta pantalla afectarán solamente el idioma actual. Para alterar en otros idiomas, utilice la pantalla de traducciones o acceda al Biblivre usando el idioma a ser alterado.	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	warning.new_version	Ya está disponible una actualización para el BIBLIVRE 5<br/>Versión instalada: {0}. Versión más reciente: {1}	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	administration.setup.progress_popup.title	Manutención del BIBLIVRE 5	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	administration.setup.biblivre4restore.log_header	[Log de restauración de backup del BIBLIVRE 5]	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	administration.translations.upload.description	Seleccione abajo el archivo de idioma que desea enviar para procesamiento por el BIBLIVRE 5.	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	administration.setup.biblivre4restore	Restaurar un Backup del Biblivre 4 o Biblivre 5	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.563156	0	f
es	multi_schema.translations.page_help	<p>El módulo de <strong>"Traducciones"</strong> de Multibibliotecas funciona de forma análoga a su versión de una única biblioteca, no obstante, los textos alterados aquí se aplicarán a todas las bibliotecas del grupo, siempre que estas no hayan alterado el valor original de cada traducción.</p>\n<p>Por ejemplo, si usted altera la traducción de la llave <strong>"menu.search"</strong> de "Búsqueda" para "Busca" por el módulo de traducciones multibibliotecas, todas las bibliotecas de este grupo verán la nueva traducción. Sin embargo, si uno de los administradores de una de estas bibliotecas alterara, a través del módulo de <strong>"Traducciones"</strong> de su biblioteca, la misma llave para "Procurar", esta traducción interna tendrá prioridad, solamente para esta biblioteca.</p>\n<p>Para agregar un nuevo idioma, baje el archivo de idioma en Portugués, realice la traducción de los textos y después envíe el archivo. Recuerde que solamente los <strong>textos</strong> (después del signo igual) deben ser alterados.  No altere las llaves, o el BIBLIVRE 5 no conseguirá localizar el texto</p>\n<p>Ejemplo: digamos que usted quiera alterar el texto en el menú principal de <i>Búsqueda</i> para <i>Busca</i>.  Usted deberá entonces bajar el archivo de idioma y alterar la siguiente línea:</p>\n<p><strong>*menu.search</strong> = Búsqueda</p>\n<p>Para:</p>\n<p><strong>*menu.search</strong> = Busca</p>\n<p>Y entonces hacer el Envío de archivo de idiomas. El BIBLIVRE 5 procesará el archivo, y alterará el texto del menú.</p>	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.setup.clean_install.description	Caso você não tenha ou não queira restaurar um backup, esta opção permitirá iniciar o uso do BIBLIVRE 5 com uma base de dados vazia. Após entrar no BIBLIVRE 5 pela primeira vez, utilize o login <strong>admin</strong> e senha <strong>abracadabra</strong> para acessar o sistema e configurar sua nova biblioteca.	2014-05-21 21:47:27.923	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.setup.progress_popup.title	Manutenção do BIBLIVRE 5	2014-05-21 21:47:27.923	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.setup.biblivre4restore.log_header	[Log de restauração de backup do BIBLIVRE 5]	2014-05-21 21:47:27.923	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.setup.biblivre4restore.error.description	Infelizmente ocorreu um erro ao restaurar este backup do BIBLIVRE 5. Verifique a próxima tela pelo log de erros e, caso necessário, entre no fórum Biblivre para obter ajuda.	2014-05-21 21:47:27.923	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.maintenance.backup.description.3	O Backup sem arquivos digitais é uma cópia de todos os dados e informações do BIBLIVRE 5, <strong>excluindo</strong> os arquivos de mídia digital. Por excluir os arquivos de mídia digital, o processo tanto de backup quanto de recuperação é mais rápido, e o arquivo de backup é menor.	2014-06-14 19:32:35.338749	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.maintenance.backup.description.1	O Backup é um processo onde executamos a cópia de informações para salvaguardá-las em caso de algum problema no sistema. É uma cópia dos registros e informações do Biblivre. O BIBLIVRE 5 possui 3 tipos de backup:	2014-06-14 19:32:35.338749	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.maintenance.backup.description.2	O Backup completo é uma cópia de todos os dados e informações do BIBLIVRE 5, incluindo os arquivos de mídia digital, como fotos dos usuários, arquivos digitais dos registros bibliográficos, etc.	2014-06-14 19:32:35.338749	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.configuration.description.general.multi_schema	Esta configuração permite que se habilite o sistema de múltiplas bibliotecas nesta instalação do BIBLIVRE 5.	2014-06-14 19:32:35.338749	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.configuration.description.multi_schema.enabled	O sistema de multi-bibliotecas já está habilitado para esta instalação do BIBLIVRE 5. O administrador do sistema poderá desabilitar essa opção no menu de configuração de multi-bibliotecas.	2014-06-14 19:32:35.338749	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.migration.page_help	<p>O módulo de <strong>"Migração de Dados"</strong> permite importar os dados constantes de uma base de dados do Biblivre 3 existente para a base de dados vazia do BIBLIVRE 5.</p>	2014-06-14 19:34:08.805257	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.translations.page_help	<p>O módulo de <strong>"Traduções"</strong> permite adicionar novos idiomas ao BIBLIVRE 5 ou alterar os textos já existentes.</p>\n<p><strong>Atenção: Este módulo realiza configurações avançadas do BIBLIVRE 5, e deve ser utilizado apenas por Usuários avançados, com experiência em informática.</strong>.</p>\n<p>Para adicionar um novo idioma, baixe o arquivo de idioma em Português, faça a tradução dos textos e depois faça o envio do arquivo. Lembre-se que apenas os <strong>textos</strong> (depois do sinal de igual) devem ser alterados.  Não altere as chaves, ou o BIBLIVRE 5 não conseguirá localizar o texto</p>\n<p>Exemplo: digamos que você queira alterar o texto no menu principal de <i>Pesquisa</i> para <i>Busca</i>.  Você deverá então baixar o arquivo do idioma e alterar a seguinte linha:</p>\n<p><strong>*menu.search</strong> = Pesquisa</p>\n<p>Para:</p>\n<p><strong>*menu.search</strong> = Busca</p>\n<p>E então fazer o Envio do arquivo de idiomas. O BIBLIVRE 5 irá processar o arquivo, e alterar o texto do menu.</p>	2014-06-14 19:34:08.805257	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.translations.upload.description	Selecione abaixo o arquivo de idioma que deseja enviar para processamento pelo BIBLIVRE 5.	2014-06-14 19:34:08.805257	1	2022-12-04 11:05:55.5474	1	f
es	multi_schema.configuration.description.general.subtitle	Subtítulo que será exhibido cuando se accede a la página principal de este grupo de bibliotecas. Esta página listará todas las bibliotecas registradas en este grupo (administradas por el mismo BIBLIVRE 5).	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
en-US	administration.maintenance.backup.description.1	Backup is a process where we copy information in order to secure them in case of problems in the system. It is a copy of the Biblivre  records and information. BIBLIVRE 5 has 3 types of backups:	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	administration.maintenance.backup.description.2	Complete Backup is a copy of all the BIBLIVRE 5 data and information, including digital media files, such as user photos, digital files of bibliographic records and so on.	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	administration.migration.page_help	<p>The  <strong>"Data Migration"</strong> module allows importing data from an existing Biblivre 3 database to the empty BIBLIVRE 5  database 4.</p>	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	administration.translations.page_help	<p> The module <strong>"Translations"</strong> allows adding new languages to BIBLIVRE 5 or modifying existing texts.</p>\n<p><strong>Attention: this module performs advanced configurations in BIBLIVRE 5, and needs to be used solely by advanced Users, experienced in IT.</strong>.</p>\n<p>To add a new language, please download the Portuguese language file, do the translation of the texts and then send the file. Remember that only the <strong>texts</strong> (after the = sign) must be translated. Do not modify the keys; if you do so, BIBLIVRE 5 will not be able to find the text </p>\n<p>Example: let´s imagine that you wish to modify the text in the main menu of <i>Search</i> to <i>Look for</i>. You will then have to download the language file and modify the following line:</p>\n<p><strong>*menu.search</strong> = Search</p>\n<p>To:</p>\n<p><strong>*menu.search</strong> = Loo for</p>\n<p>And then deliver the language file. BIBLIVRE 5 will process the file and will modify the menu text.</p>	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	administration.maintenance.reinstall.confirm.description	Do you wish to go to the restoration and reconfiguration screen? You will be able to restore a BIBLIVRE 5 backup, delete data in your library or redo a migration	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	administration.setup.clean_install.description	If you do not have or do not wish to restore a backup, this option will allow start using BIBLIVRE 5 with an empty database. When entering BIBLIVRE 5 for the first time, use the <strong>admin</strong> and password <strong>abracadabra</strong> to access the system and configure your new library.	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	multi_schema.configuration.description.general.title	Nome to be shown when the main page of the library group is accessed. o que será exibido quando a página principal deste grupo de bibliotecas for acessada. This page will list all the registered libraries in this group (managed by the same BIBLIVRE 5).	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	multi_schema.manage.page_help	The multi-libraries screen allows registering several libraries to be managed by a single Biblivre. Since the moment the multi-libraries system is in action, the list of registered libraries will be shown when the person accesses the standard BIBLIVRE 5 address.	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	administration.configuration.description.general.multi_schema	This configuration allows setting up the multiple library system in this BIBLIVRE 5 installation.	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	multi_schema.manage.log_header	[New BIBLIVRE 5 Library Log]	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	multi_schema.manage.new_schema.description	To create a new library, please fill in below your name and an optional subtitle. You will also need a short name for the library, which is called shortcut, to be used in the web address for accessing BIBLIVRE 5, which allows differentiation among different libraries installed in the system. This shortcut must contain only letters, numbers and the character _. To make things easier, BIBLIVRE 5 will automatically suggest a shortcut, based on the library name.	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	administration.maintenance.reinstall.description	Use this option if you wish to restore a BIBLIVRE 5 backup, or to delete data in your library or to redo Biblivre 3 migration. You will be taken to the Biblivre install initial screen, and you may cancel the operation if you do not wish to make modifications.	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	administration.setup.progress_popup.title	BIBLIVRE 5 maintenance	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	administration.setup.biblivre4restore.log_header	[Log for BIBLIVRE 5 backup restoration]	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	administration.configuration.description.multi_schema.enabled	The multi-library system is already active for this BIBLIVRE 5 installation. The system administrator can deactivate this option in the multi-library configuration menu.	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
pt-BR	multi_schema.select_restore.description	Use esta opção caso você queira restaurar um backup existente do Biblivre 4. Caso o Biblivre encontre backups salvos em seus documentos, você poderá restaurá-los diretamente da lista abaixo. Caso contrário, você deverá enviar um arquivo de backup (extensão <strong>.b4bz</strong>) através do formulário.	2014-07-19 13:50:48.346587	1	2022-12-04 11:05:55.560476	0	f
en-US	multi_schema.select_restore.description	Use this option if you wish to restore an existing Biblivre 4 backup. When the Biblivre find backups saved among your documents, you will be able to restore the, directly from the list below. Otherwise, you will have to send a backup file (extension <strong>.b4bz</strong>) through the form.	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.561088	0	f
en-US	administration.setup.biblivre4restore	Restore a Biblivre 4 or Biblivre 5 Backup	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.562589	0	f
en-US	multi_schema.manage.schemas.description	Please see below all the libraries registered in this BIBLIVRE 5. Should you wish to modify a name or subtitle, please go to the configurations screen of the Library.	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	administration.setup.biblivre4restore.error.description	Regrettably an error occurred when restoring this BIBLIVRE 5  backup. Check next screen through the error log and, if necessary, go to the Biblivre forum for assistance.	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	multi_schema.configuration.description.general.subtitle	Subtitle shown when the main page in this library broup is accessed. This page will list all the registered libraries in this group (managed by the same BIBLIVRE 5).	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	warning.new_version	There's an update for BIBLIVRE 5 available<br/>Current Version: {0}. Latest version: {1}	2014-07-26 12:01:11.320131	1	2022-12-04 11:05:55.5474	1	f
en-US	multi_schema.translations.page_help	<p>The module of <strong>"Translations"</strong> for Multilibraries Works similarly to the version corresponding to just one library. However, texts which were modified here will be applied to all the libraries in the group, provided they have not modified the original value of each translation.</p>\n<p>For example, if you modify the translation of the key <strong>"menu.search"</strong> from "Search" to "Trace" through the Translations module for multi-libraries, all the libraries in this group will see the new translation. However, if one of the administrators of one of these libraries modifies, through the <strong>"Translations"</strong> module of his library, the same key to "Search", this in-house translation will have priority just for this library.</p>\n<p>In order to add a new language, you will have to download the language file in Portuguese, do the translation of the texts and then upload the file. Remember that only the <strong>texts</strong> (after the = sign) must be modified.  Do not modify the keys, as otherwise the BIBLIVRE 5 will not be able to trace the text </p>\n<p>Example: Let´s say that you wish to modify the text in the main menu from <i>Search</i> to <i>Trace</i>.  You will have to download the language file and modify this line:</p>\n<p><strong>*menu.search</strong> = Search</p>\n<p>To:</p>\n<p><strong>*menu.search</strong> = Trace</p>\n<p>and then upload the language file. BIBLIVRE 5 will process the file and will modify the menu text.</p>	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.setup.biblivre4restore.select_file	Selecione um arquivo de backup do BIBLIVRE 5	2014-06-14 19:32:35.338749	1	2022-12-04 11:05:55.5474	0	f
en-US	administration.setup.biblivre4restore.select_file	Select a BIBLIVRE 5 backup file	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	0	f
es	administration.setup.biblivre4restore.select_file	Seleccione un archivo de copia de seguridad BIBLIVRE 5	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	0	f
pt-BR	text.main.logged_in	<p>Olá {0},</p>\n<p>Seja bem-vindo ao <strong>Biblioteca Livre (Biblivre) vERSÃO 5.0</strong>.</p>\n<p>Você poderá fazer pesquisas por registros bibliográficos, autoridades e vocabulário pela opção <em>"Pesquisa"</em> no menu superior. Esta é a mesma <em>"Pesquisa"</em> que os leitores poderão usar ao acessar o <strong>Biblivre</strong>, sem necessidade de usuário e senha, para pesquisar por registros na Base Principal.</p>\n<p>Para cadastrar leitores, realizar empréstimos, devoluções e reservas, controlar o acesso à biblioteca e imprimir carteirinhas, use a opção <em>"Circulação"</em>, também no menu superior.</p>\n<p>Na opção <em>"Catalogação"</em>, você poderá controlar o acervo da biblioteca, catalogando obras e exemplares, e efetuar o controle de autoridades e do vocabulário. Através desta opção tambem é possível imprimir as etiquetas usadas nos exemplares, mover registros entre as bases de dados (Principal, Trabalho, Privada e Lixeira), importar e exportar registros e adicionar arquivos digitais aos registros existentes.</p>\n<p>O <strong>Biblivre</strong> também possui um sistema simples de controle do processo de aquisição, para auxiliar a compra e recebimento de publicações, através da opção <em>"Aquisição"</em>.</p>\n<p>Em <em>"Administração"</em>, você poderá trocar a senha de acesso, configurar recursos do <strong>Biblivre</strong> como campos dos formulários, traduções e tipos de usuário, cadastrar cartões de acesso, gerar relatórios e realizar a manutenção da base de dados, que inclui a geração da cópia de segurança (backup), e a reindexação da base de dados, que deve ser usada quando alguns registros não puderem ser encontrados através da pesquisa.</p>\n<p>Caso precise de mais informações sobre o <strong>Biblivre</strong>, acesse a opção <em>"Ajuda"</em> e leia o Manual do programa ou as perguntas frequentes, no <a href="http://biblivre.org.br/forum" target="_blank">Fórum</a>.</p>	2014-06-14 19:34:08.805257	1	2022-12-04 11:05:55.5474	1	f
pt-BR	text.main.logged_out	<p>O programa <strong>Biblioteca Livre (Biblivre) vERSÃO 5.0</strong> é um aplicativo que permite a inclusão digital do cidadão na sociedade da informação. Saiba mais sobre o projeto em <em>"Sobre"</em>, na opção <em>"Ajuda"</em> no menu superior.</p>\n<p>Trata-se de um programa para catalogação e difusão de acervos de bibliotecas públicas e privadas, de variados portes, além de possibilitar a circulação e o compartilhamento de conteúdos de informação, tais como, textos, músicas, imagens e filmes ou qualquer outro tipo de objeto digital.</p>\n<p>Hoje, o <strong>Biblivre</strong> é sucesso em todo o Brasil, assim como no exterior e, por sua extrema relevância cultural, vem se firmando como o aplicativo de escolha para a inclusão digital do cidadão.</p>\n<p>Se desejar somente pesquisar o catálogo e acessar as obras disponíveis digitalmente, utilize a opção <em>"Pesquisa"</em> no menu superior, sem a necessidade de usuário e senha.</p>\n<p>Para outros serviços, tais como circulação, catalogação, aquisição e administração, é necessário um nome de <strong>usuário</strong> e <strong>senha</strong>.</p>	2014-06-14 19:34:08.805257	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.setup.biblivre4restore.description	Use esta opção caso você queira restaurar um backup existente do Biblivre 4. Caso o Biblivre encontre backups salvos em seus documentos, você poderá restaurá-los diretamente da lista abaixo. Caso contrário, você deverá enviar um arquivo de backup (extensão <strong>.b4bz</strong> ou <strong>.b5bz</strong>) através do formulário.	2014-05-21 21:47:27.923	1	2022-12-04 11:05:55.558477	0	f
en-US	administration.setup.biblivre4restore.description	Use this option should you wish to restore an existing Biblivre 4 backup. Should Biblivre find backups saved in your documents, you will be able to restore them directly from the list below. Otherwise, you will have to send a backup file (extension <strong>.b4bz</strong> or <strong>.b5bz</strong>) by means of the form.	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.559207	0	f
en-US	text.main.logged_in	<p>Hello {0},</p>\n<p>Welcome to the <strong>Free Library (Biblivre) vERSION 5.0</strong>.</p>\n<p>You may conduct searches by Bibliographic Records, Authorities and Vocabulary through the option <em>"Search"</em> in the upper menu. This is the same <em>"Search"</em> that readers may use when accessing <strong>Biblivre</strong>, without the need of username and password when searching for records in the Main Base.</p>\n<p>In order to register readers, make loans, returns and reservations, and also to control access to the library and print user cards, please use the option <em>"Circulation"</em>, also in the upper menu.</p>\n<p>In the option <em>"Cataloging"</em>, you will be able to control the collections of the library, and to catalog Works and copies, and also carry out controls on Authorities and Vocabulary. Also through this option you can print labels used in copies or units, and move records among databases (Main, Work, Private and Recycle Bin), import and export records and add digital files to the existing records.</p>\n<p> <strong>Biblivre</strong> also has a control system for the acquisition process, in order to assist in the purchase and reception of publication, through the option <em>"Acquisition"</em>.</p>\n<p>In <em>"Administration"</em>, you will be able to change access passwords, configure <strong>Biblivre</strong> resources, such as forms fields, translations and user types, register access cards, create reports and conduct maintenance services in the database, which include the generation of backups and the reindexing of the database, which must be used when some records cannot be found in the searches.</p>\n<p>Should you need additional information on  <strong>Biblivre</strong>, please go to the option <em>"Help"</em> and read the Manual of the program or the FAQs, in <a href="http://biblivre.org.br/forum" target="_blank">Forum</a>.</p>	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	text.main.logged_out	<p>The program <strong>Free Library (Biblivre) vERSION 5.0</strong> is an application promoting the digital inclusion of the citizen in the information society. Know more about the project in <em>"About"</em>, in the option <em>"Help"</em> in the upper menu.</p>\n<p>It is a program involving cataloging and the dissemination of collections from public and private libraries, of varied sizes, in addition to promoting the circulation and sharing of information content, such as texts, music, images and films or any other kind of digital object.</p>\n<p>Today <strong>Biblivre</strong> is successful throughout Brazil as well as abroad and, in view of its high cultural importance, it is consolidating as the preferential application for the digital inclusion of citizens.</p>\n<p>If you wish to search the catalogue and have access to the digital works available, please use the option <em>"Search"</em> in the upper menu. No username or password is required.</p>\n<p>For other services, such as circulation, cataloging, acquisition and administration, you will need a <strong>username</strong> and <strong>password</strong>.</p>	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
es	administration.setup.page_help	¡Bienvenido! Esta pantalla es el último paso antes de iniciar el uso del BIBLIVRE V y a través de ella usted podrá escoger si restaurará las informaciones de otra instalación del biblivre (a través de un backup o de la migración del Biblivre 3) o si desea iniciar una biblioteca nueva. Lea atentamente cada una de las opciones abajo y seleccione la más apropiada.	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	login.welcome	Sea bienvenido al BIBLIVRE V	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
pt-BR	administration.setup.page_help	Seja bem-vindo! Esta tela é o último passo antes de iniciar o uso do BIBLIVRE V e através dela você poderá escolher se irá restaurar as informações de outra instalação do biblivre (através de um backup ou da migração do Biblivre 3) ou se deseja iniciar uma biblioteca nova. Leia atentamente cada uma das opções abaixo e selecione a mais apropriada.	2014-05-21 21:47:27.923	1	2022-12-04 11:05:55.5474	1	f
pt-BR	login.welcome	Seja bem-vindo ao BIBLIVRE V	2014-06-14 19:34:08.805257	1	2022-12-04 11:05:55.5474	1	f
en-US	administration.setup.page_help	Welcome! This screen is the last one before starting to use BIBLIVRE V and through it you will be able to choose whether to restore the information from another Biblivre installation (by means of a backup or through a migration of Biblivre 3) or if you wish to start a new library. Please read each option below carefully and select the most appropriate one.	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
en-US	login.welcome	Welcome to BIBLIVRE V	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
es	text.main.logged_in	<p>Hola {0},</p>\n<p>Sea bienvenido a la <strong>Biblioteca Libre (Biblivre) vERSIÓN 5.0</strong>.</p>\n<p>Usted podrá hacer búsquedas por registros bibliográficos, autoridades y vocabulario con la opción <em>"Búsqueda"</em> en el menú superior. Esta es la misma <em>"Búsqueda"</em> que los lectores podrán usar al accesar al <strong>Biblivre</strong>, sin necesidad de usuario y contraseña, para buscar por registros en la Base Principal.</p>\n<p>Para registrar lectores, realizar préstamos, devoluciones y reservas, controlar el acceso a la biblioteca e imprimir carnets, use la opción <em>"Circulación"</em>, también en el menú superior.</p>\n<p>En la opción <em>"Catalogación"</em>, usted podrá controlar el acervo de la biblioteca, catalogando obras y ejemplares, y efectuar el control de autoridades y de vocabulario. A través de esta opción también es posible imprimir las etiquetas usadas en los ejemplares, mover registros entre las bases de datos (Principal, Trabajo, Privada y Papelera de reciclaje), importar y exportar registros y agregar archivos digitales a los registros existentes.</p>\n<p>El <strong>Biblivre</strong> también posee un sistema simple de control del proceso de adquisición, para auxiliar la compra y recibimiento de publicaciones, a través de la opción <em>"Adquisición"</em>.</p>\n<p>En <em>"Administración"</em>, usted podrá cambiar la contraseña de acceso, configurar recursos del <strong>Biblivre</strong> como campos de los formularios, traducciones y tipos de usuario, registrar tarjetas de acceso, generar informes y realizar la manutención de la base de datos, que incluye la generación de la copia de seguridad (backup), y la Reindización de la base de datos, que debe ser usada cuando algunos registros no pueden ser encontrados a través de la búsqueda.</p>\n<p>En caso que precise de más informaciones sobre el <strong>Biblivre</strong>, accese a la opción <em>"Ayuda"</em> y lea el Manual del programa o las preguntas frecuentes, en <a href="http://biblivre.org.br/forum" target="_blank">Fórum</a>.</p>	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
es	text.main.logged_out	<p>El programa <strong>Biblioteca Libre (Biblivre) vERSIÓN 5.0</strong> es un aplicativo que permite la inclusión digital del ciudadano en la sociedad de la información. Sepa más sobre el proyecto en <em>"Sobre"</em>, en la opción <em>"Ayuda"</em> en el menú superior.</p>\n<p>Se trata de un programa para catalogación y difusión de acervos de bibliotecas públicas y privadas, de variados portes, además de posibilitar la circulación y el compartir contenidos de información, tales como, textos, músicas, imágenes y películas o cualquier otro tipo de objeto digital.</p>\n<p>Hoy, el <strong>Biblivre</strong> es un éxito en todo Brasil, así como en el exterior y, por su extrema relevancia cultural, se viene asentando como el aplicativo de elección para la inclusión digital del ciudadano.</p>\n<p>Si desea solamente buscar el catálogo y accesar a las obras disponibles digitalmente, utilize la opción <em>"Búsqueda"</em> en el menú superior, sin la necesidad de usuario y contraseña.</p>\n<p>Para otros servicios, tales como circulación, catalogación, adquisición y administración, es necesario un nombre de <strong>usuario</strong> y <strong>contraseña</strong>.</p>	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.5474	1	f
en-US	administration.maintenance.backup.description.3	Backup without digital files is a copy of all the BIBLIVRE 5 data and information, <strong>excluding</strong> digital media files. In view of the exclusion of digital media files, the backup and retrieval processes are faster, and the backup file is smaller.	2014-07-26 10:56:18.338867	1	2022-12-04 11:05:55.5474	1	f
es	administration.setup.biblivre4restore.description	Use esta opción en caso que usted quiera restaurar un backup existente del Biblivre 4. En caso que el Biblivre encuentre backups guardados en sus documentos, usted podrá restaurarlos directamente de la lista abajo. En caso contrario, usted deberá enviar un archivo de backup (extensión <strong>.b4bz</strong> o <strong>.b5bz</strong>) a través del formulario.	2014-07-19 11:28:46.69376	1	2022-12-04 11:05:55.559838	0	f
es	multi_schema.select_restore.description	Use esta opción en caso de desear restaurar un backup existente del Biblivre 4. En el caso de que el Biblivre encuentre backups guardados en sus documentos, usted podrá restaurarlos directamente de la lista siguiente. De lo contrario, usted deberá enviar un archivo de backup (extensión <strong>.b4bz</strong>) a través del formulario.	2014-07-26 10:56:23.669888	1	2022-12-04 11:05:55.561536	0	f
en-US	cataloging.reservation.error.limit_exceeded	The selected reader surpassed the limit of authorized loans	2022-12-04 11:05:55.565274	0	2022-12-04 11:05:55.565274	0	f
pt-BR	cataloging.reservation.error.limit_exceeded	O leitor selecionado ultrapassou o limite de reservas permitidas	2022-12-04 11:05:55.566107	0	2022-12-04 11:05:55.566107	0	f
es	cataloging.reservation.error.limit_exceeded	El lector seleccionado excedió el límite de reservas permitidas	2022-12-04 11:05:55.566758	0	2022-12-04 11:05:55.566758	0	f
en-US	cataloging.import.error.file_upload_error	Couldn't upload file. Please contact the administrator to analyze thisproblem.	2022-12-04 11:05:55.567263	0	2022-12-04 11:05:55.567263	0	f
pt-BR	cataloging.import.error.file_upload_error	Não foi possível fazer upload do arquivo. Por favor, contacte o administrador do sistema para anlizar este problema.	2022-12-04 11:05:55.56766	0	2022-12-04 11:05:55.56766	0	f
es	cataloging.import.error.file_upload_error	No ha sido posible subir el archivo. Por favor, contacta el administrador del sistema para analizar este problema.	2022-12-04 11:05:55.568049	0	2022-12-04 11:05:55.568049	0	f
\.


--
-- Data for Name: versions; Type: TABLE DATA; Schema: global; Owner: biblivre
--

COPY global.versions (installed_versions) FROM stdin;
4.0.0b
4.0.1b
4.0.2b
4.0.3b
4.0.4b
4.0.5b
4.0.6b
4.0.7b
4.0.8b
4.0.9b
4.0.10b
4.0.11b
4.0.12b
4.1.0
4.1.1
4.1.2
4.1.3
4.1.4
4.1.5
4.1.6
4.1.7
4.1.8
4.1.9
4.1.10
4.1.10a
4.1.11
4.1.11a
5.0.0
5.0.1
5.0.1b
6.0.0-1.0.0-alpha
6.0.0-1.0.1-alpha
6.0.0-1.0.2-alpha
v6_0_0$1_1_0$alpha
\.


--
-- Name: backups_id_seq; Type: SEQUENCE SET; Schema: global; Owner: biblivre
--

SELECT pg_catalog.setval('global.backups_id_seq', 1, false);


--
-- Name: logins_id_seq; Type: SEQUENCE SET; Schema: global; Owner: biblivre
--

SELECT pg_catalog.setval('global.logins_id_seq', 2, false);


--
-- Name: configurations PK_configurations; Type: CONSTRAINT; Schema: global; Owner: biblivre
--

ALTER TABLE ONLY global.configurations
    ADD CONSTRAINT "PK_configurations" PRIMARY KEY (key);


--
-- Name: logins PK_logins; Type: CONSTRAINT; Schema: global; Owner: biblivre
--

ALTER TABLE ONLY global.logins
    ADD CONSTRAINT "PK_logins" PRIMARY KEY (id);


--
-- Name: schemas PK_schemas; Type: CONSTRAINT; Schema: global; Owner: biblivre
--

ALTER TABLE ONLY global.schemas
    ADD CONSTRAINT "PK_schemas" PRIMARY KEY (schema);


--
-- Name: translations PK_translations; Type: CONSTRAINT; Schema: global; Owner: biblivre
--

ALTER TABLE ONLY global.translations
    ADD CONSTRAINT "PK_translations" PRIMARY KEY (language, key);


--
-- Name: versions PK_versions; Type: CONSTRAINT; Schema: global; Owner: biblivre
--

ALTER TABLE ONLY global.versions
    ADD CONSTRAINT "PK_versions" PRIMARY KEY (installed_versions);


--
-- Name: logins UN_logins; Type: CONSTRAINT; Schema: global; Owner: biblivre
--

ALTER TABLE ONLY global.logins
    ADD CONSTRAINT "UN_logins" UNIQUE (login);


--
-- PostgreSQL database dump complete
--

