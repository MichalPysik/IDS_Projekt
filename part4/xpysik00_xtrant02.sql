-- IDS Projekt část 4 - SQL skript pro vytvoření pokročilých objektů databáze
-- Autor: Michal Pyšík (login: xpysik00)
-- Autor: Michal Tran (login: xtrant02)




---- Smazání tabulek, sekvencí, atd. vytvořených při ředešlém spuštění skriptu - DROP

DROP TABLE autor CASCADE CONSTRAINTS;
DROP TABLE uzivatel CASCADE CONSTRAINTS;
DROP TABLE manga CASCADE CONSTRAINTS;
DROP TABLE zanr CASCADE CONSTRAINTS;
DROP TABLE vydavatelstvi CASCADE CONSTRAINTS;
DROP TABLE episoda CASCADE CONSTRAINTS;
DROP TABLE magazin CASCADE CONSTRAINTS;
DROP TABLE svazek CASCADE CONSTRAINTS;
DROP TABLE objednavka CASCADE CONSTRAINTS;
DROP TABLE adresa CASCADE CONSTRAINTS;
DROP TABLE polozka CASCADE CONSTRAINTS;

DROP SEQUENCE polozka_id_liche;
DROP SEQUENCE polozka_id_sude;




---- Tvorba nových tabulek - CREATE TABLE

CREATE TABLE zanr (
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    nazev VARCHAR(128) NOT NULL
);


CREATE TABLE adresa (
    cislo_popisne INTEGER NOT NULL,
    psc CHAR(5) NOT NULL
        CHECK(REGEXP_LIKE(psc, '[0-9]{5}')), -- PSC ma opet fixni pocet cislic
    PRIMARY KEY(cislo_popisne, psc), --slozeny PK
    ulice VARCHAR(64) NOT NULL,
    cislo_domu INT DEFAULT NULL,
    zeme VARCHAR(64) NOT NULL,
    mesto VARCHAR(64) DEFAULT NULL
);


CREATE TABLE autor (
    ico CHAR(8) NOT NULL PRIMARY KEY
        CHECK(REGEXP_LIKE(ico, '[0-9]{8}')), -- ICO osoby je osmimistne cislo bez znamenka (dekadicky, cislic musi byt vzdy 8 - proto CHAR a ne VARCHAR, INT ani NUMBER)
    jmeno VARCHAR(64) NOT NULL,
    prijmeni VARCHAR(64) NOT NULL,
    datum_narozeni DATE DEFAULT NULL,
    bydliste VARCHAR(128) DEFAULT NULL, -- pozor: bydliste neni nutne adresa, ani nemusi byt uvedeno
    zanr_id INT DEFAULT NULL,
    CONSTRAINT venuje_se_zanru_id_fk
        FOREIGN KEY (zanr_id) REFERENCES zanr (id)
        ON DELETE SET NULL
);


CREATE TABLE uzivatel (
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    jmeno VARCHAR(64) NOT NULL,
    prijmeni VARCHAR(64) NOT NULL,
    heslo VARCHAR(128) NOT NULL, -- Pozor! Nový atribut oproti předchozím skriptům
    datum_narozeni DATE NOT NULL, -- musi uvest, napriklad male dite si nesmi nic objednavat
    telefon NUMBER(14) NOT NULL, -- az 9 cislic + pripadny prefix (+420 zapiseme jako 00420) -> 5 + 9 = 14 cislic
    email VARCHAR(128) NOT NULL
        CHECK(REGEXP_LIKE(email, '^[a-z][a-z0-9_\.-]*@[a-z0-9_\.-]+\.[a-z]{2,}$', 'i')),
    adresa_cp INTEGER NOT NULL,
    adresa_psc CHAR(5) NOT NULL,
    CONSTRAINT bydli_na_adrese_cp_psc_fk
        FOREIGN KEY (adresa_cp, adresa_psc) REFERENCES adresa (cislo_popisne, psc)
        ON DELETE CASCADE,
    spravce SMALLINT DEFAULT 0 NOT NULL
);


CREATE TABLE vydavatelstvi (
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    nazev VARCHAR(128) NOT NULL
);


CREATE TABLE magazin (
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    nazev VARCHAR(128) NOT NULL,
    datum_vydani DATE NOT NULL,
    cena NUMBER(10, 2) NOT NULL, --v mnoha menach se udava cena i s 2 desetinnymi misty
    vydavatelstvi_id INT NOT NULL,
    CONSTRAINT vydavan_vydavatelstvim_id_fk
        FOREIGN KEY (vydavatelstvi_id) REFERENCES vydavatelstvi (id)
        ON DELETE CASCADE
);


CREATE TABLE svazek (
    isbn CHAR(10) NOT NULL PRIMARY KEY
        CHECK(REGEXP_LIKE(isbn, '[0-9]{10}')), -- standard ISBN-10, NE ISBN-13
    poradove_cislo NUMBER(8, 2) NOT NULL,
    datum_vydani DATE NOT NULL,
    pocet_stran INT DEFAULT NULL,
    cena NUMBER(10, 2) NOT NULL
);


CREATE TABLE manga (
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    nazev VARCHAR(128) NOT NULL,
    zacatek_vydavani DATE NOT NULL,
    konec_vydavani DATE DEFAULT NULL, --konec nemusi byt uveden pokud je manga stale vydavana
    zanr_id INT NOT NULL,
    CONSTRAINT je_zanrem_id_fk
        FOREIGN KEY (zanr_id) REFERENCES zanr (id)
        ON DELETE CASCADE,
    vydavatelstvi_id INT NOT NULL,
    CONSTRAINT vydavana_vydavatelstvim_id_fk
        FOREIGN KEY (vydavatelstvi_id) REFERENCES vydavatelstvi (id)
        ON DELETE CASCADE,
    autor_ico CHAR(8) NOT NULL,
    CONSTRAINT napsana_autorem_ico_fk
        FOREIGN KEY (autor_ico) REFERENCES autor (ico)
        ON DELETE CASCADE,
    kreslir_ico CHAR(8) NOT NULL,
    CONSTRAINT namalovana_kreslirem_ico_fk
        FOREIGN KEY (kreslir_ico) REFERENCES autor (ico)
        ON DELETE CASCADE
);


CREATE TABLE episoda (
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    nazev VARCHAR(128) NOT NULL,
    poradove_cislo NUMBER(8, 2) NOT NULL, -- az 2 desetinne cislice, napriklad cislo 2.3 je validni
    datum_vydani DATE NOT NULL,
    pocet_stran INT DEFAULT NULL,
    manga_id INT NOT NULL,
    CONSTRAINT epizoda_mangy_id_fk
        FOREIGN KEY (manga_id) REFERENCES manga (id)
        ON DELETE CASCADE,
    svazek_isbn CHAR(10) DEFAULT NULL,
    CONSTRAINT soucasti_svazku_isbn_fk
        FOREIGN KEY (svazek_isbn) REFERENCES svazek (isbn)
        ON DELETE SET NULL,
    magazin_id INT DEFAULT NULL,
    CONSTRAINT soucasti_magazinu_id_fk
        FOREIGN KEY (magazin_id) REFERENCES magazin (id)
        ON DELETE SET NULL,
    CONSTRAINT soucasti_neceho -- Kontroluje ze je soucasti alespon jedne epizody nebo svazku
        CHECK(svazek_isbn IS NOT NULL OR magazin_id IS NOT NULL)
);


CREATE TABLE objednavka (
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    datum DATE NOT NULL,
    cena NUMBER(10, 2) NOT NULL,
    stav VARCHAR(12) NOT NULL
        CHECK(stav IN('prijata', 'zaplacena', 'odeslana', 'stornovana')),
    uzivatel_id INT NOT NULL,
    CONSTRAINT vytvoril_uzivatel_id_fk
        FOREIGN KEY (uzivatel_id) REFERENCES uzivatel (id)
        ON DELETE CASCADE,
    adresa_cp INTEGER NOT NULL,
    adresa_psc CHAR(5) NOT NULL,
    CONSTRAINT na_adresu_cp_psc_fk
        FOREIGN KEY (adresa_cp, adresa_psc) REFERENCES adresa (cislo_popisne, psc)
        ON DELETE CASCADE
);


CREATE TABLE polozka (
    id INT DEFAULT NULL PRIMARY KEY, -- POZOR! zmena oproti predchozim skriptum!
    objednavka_id INT NOT NULL,
    CONSTRAINT soucasti_objednavky_id_fk
        FOREIGN KEY (objednavka_id) REFERENCES objednavka (id)
        ON DELETE CASCADE,
    svazek_isbn CHAR(10) DEFAULT NULL,
    CONSTRAINT je_svazek_isbn_fk
        FOREIGN KEY (svazek_isbn) REFERENCES svazek (isbn)
        ON DELETE CASCADE,
    magazin_id INT DEFAULT NULL,
    CONSTRAINT je_magazin_id_fk
        FOREIGN KEY (magazin_id) REFERENCES magazin (id)
        ON DELETE CASCADE,
    mnozstvi INT DEFAULT 1 NOT NULL
        CHECK(mnozstvi > 0),
    CONSTRAINT neni_prazdna_polozka -- Polozka nesmi byt prazdna
        CHECK(svazek_isbn IS NOT NULL OR magazin_id IS NOT NULL),
    CONSTRAINT neni_vicenasobna_polozka -- Polozka vsak musi obsahovat bud pouze magazin, nebo pouze svazek!
        CHECK(svazek_isbn IS NULL OR magazin_id IS NULL)
);




---- Nastavení triggerů - TRIGGER (part 1/2)

-- První trigger generuje hodnotu ID nové položky v objednávce
-- pokud je množství dané položky 1, generuje následující liché číslo v sekvenci lichých čísel
-- pokud je množství dané položky > 1, generuje následující sudé číslo v sekv. sud. čísel (třeba pro rychlé odlišení množství už pomocí ID)
CREATE SEQUENCE polozka_id_liche
    START WITH 1
    INCREMENT BY 2;
CREATE SEQUENCE polozka_id_sude
    START WITH 2
    INCREMENT BY 2;
CREATE OR REPLACE TRIGGER id_polozky_parita
    BEFORE INSERT ON polozka
    FOR EACH ROW
    WHEN (NEW.id IS NULL)
    BEGIN
        IF (:NEW.mnozstvi > 1) THEN
            :NEW.id := polozka_id_sude.NEXTVAL;
        ELSE
            :NEW.id := polozka_id_liche.NEXTVAL;
        END IF;
    END;
/

-- Druhý trigger generuje hash uživatelova hesla, aby nebylo uloženo jako raw text
CREATE OR REPLACE TRIGGER hash_hesla
    BEFORE INSERT ON uzivatel
    FOR EACH ROW
    BEGIN
        :NEW.heslo := DBMS_OBFUSCATION_TOOLKIT.MD5(input => UTL_I18N.STRING_TO_RAW(:NEW.heslo));
    END;
/
      
   


---- Tvorba instancí (vkládání do tabulek) - INSERT INTO

INSERT INTO zanr (nazev)
VALUES ('Shonen');
INSERT INTO zanr (nazev)
VALUES ('Seinem');
INSERT INTO zanr (nazev)
VALUES ('Kodomomuke');


INSERT INTO adresa (cislo_popisne, psc, ulice, cislo_domu, zeme, mesto)
VALUES (4271, 64300,'Meulerova', 12, 'Česká republika', 'Brno');
INSERT INTO adresa (cislo_popisne, psc, ulice, zeme, mesto)
VALUES (1337, 23600, 'Grove Street', 'USA', 'Los Santos');
INSERT INTO adresa (cislo_popisne, psc, ulice, cislo_domu, zeme, mesto)
VALUES (998, 42069, 'Tech Street', 2, 'USA', 'Los Angeles');


INSERT INTO autor (ico, jmeno, prijmeni, datum_narozeni, bydliste, zanr_id)
VALUES ('00425691', 'Hitsune', 'Yamaka', TO_DATE('1997-05-21', 'yyyy/mm/dd'), 'somewhere in the mountains in Japan', 1);
INSERT INTO autor (ico, jmeno, prijmeni)
VALUES ('01010101', 'Hasan', 'Paranoidan'); -- pokud nejake cislo zacina explicitni nulou, je treba ho zapsat s jednoduchyma uvozovkama ''
INSERT INTO autor (ico, jmeno, prijmeni, datum_narozeni, zanr_id)
VALUES (74630014, 'Yoshi', 'Miu', TO_DATE('1985-09-13', 'yyyy/mm/dd'), 3);


-- zde tentokrat vkladame take heslo, ktere spusti trigger na generaci hashe
INSERT INTO uzivatel (jmeno, prijmeni, datum_narozeni, telefon, email, adresa_cp, adresa_psc, heslo)
VALUES ('Carl', 'Johnson', TO_DATE('1962-03-09', 'yyyy/mm/dd'), 34645501111, 'CJ_straight-busta@grove.family.com', 1337, 23600, 'BigSmokeIsFatass');
INSERT INTO uzivatel (jmeno, prijmeni, datum_narozeni, telefon, email, adresa_cp, adresa_psc, heslo)
VALUES ('Martin', 'Dobrak', TO_DATE('2001-11-13', 'yyyy/mm/dd'), '00420773516991', 'martus322@seznam.cz', 4271, 64300, 'mOJeHeSLo147');
INSERT INTO uzivatel (jmeno, prijmeni, datum_narozeni, telefon, email, adresa_cp, adresa_psc, heslo)
VALUES ('Linus', 'Sebastian', TO_DATE('1986-03-21', 'yyyy/mm/dd'), 456987123, 'linusTechTips@ltt-store.com', 998, 42069, 't3chT1pZz');
INSERT INTO uzivatel (jmeno, prijmeni, datum_narozeni, telefon, email, adresa_cp, adresa_psc, heslo)
VALUES ('Klementina', 'Dobrakova', TO_DATE('1973-04-29', 'yyyy/mm/dd'), '00420368741298', 'martinova.mama@seznam.cz', 4271, 64300, 'heslo123');


INSERT INTO vydavatelstvi (nazev)
VALUES ('Albatros');
INSERT INTO vydavatelstvi (nazev)
VALUES ('MangaTron');


INSERT INTO magazin (nazev, datum_vydani, cena, vydavatelstvi_id)
VALUES ('MangaCritics', TO_DATE('2018-08-01', 'yyyy/mm/dd'), 21.99, 2);
INSERT INTO magazin (nazev, datum_vydani, cena, vydavatelstvi_id)
VALUES ('Best of Naruto', TO_DATE('2020-02-27', 'yyyy/mm/dd'), 199, 1);
INSERT INTO magazin (nazev, datum_vydani, cena, vydavatelstvi_id)
VALUES ('Super Saiyan strikes again', TO_DATE('1998-08-30', 'yyyy/mm/dd'), 1199, 1);


INSERT INTO svazek (isbn, poradove_cislo, datum_vydani, pocet_stran, cena)
VALUES (1234567890, 2.1, TO_DATE('2019-10-10', 'yyyy/mm/dd'), 209, 400);
INSERT INTO svazek (isbn, poradove_cislo, datum_vydani, cena)
VALUES ('0012478902', 11, TO_DATE('2001-01-02', 'yyyy/mm/dd'), 299);


INSERT INTO manga (nazev, zacatek_vydavani, zanr_id, vydavatelstvi_id, autor_ico, kreslir_ico)
VALUES ('Naruto', TO_DATE('1999-05-13', 'yyyy/mm/dd'), 1, 2, '00425691', '00425691');
INSERT INTO manga (nazev, zacatek_vydavani, konec_vydavani, zanr_id, vydavatelstvi_id, autor_ico, kreslir_ico)
VALUES ('Attack on Titan', TO_DATE('2003-06-14', 'yyyy/mm/dd'), TO_DATE('2021-03-07', 'yyyy/mm/dd'), 1, 1, '00425691', '01010101');
INSERT INTO manga(nazev, zacatek_vydavani, zanr_id, vydavatelstvi_id, autor_ico, kreslir_ico)
VALUES ('Super Mario', TO_DATE('1985-08-23', 'yyyy/mm/dd'), 3, 2, 74630014, '01010101');
INSERT INTO manga (nazev, zacatek_vydavani, zanr_id, vydavatelstvi_id, autor_ico, kreslir_ico)
VALUES ('Dragon Ball Z', TO_DATE('2003-12-24', 'yyyy/mm/dd'), 2, 1, '00425691', '01010101');


INSERT INTO episoda (nazev, poradove_cislo, datum_vydani, pocet_stran, manga_id, magazin_id)
VALUES ('Narutova prvni dobrodruzstvi', 1.1, TO_DATE('1999-05-13', 'yyyy/mm/dd'), 97, 1, 2);
INSERT INTO episoda (nazev, poradove_cislo, datum_vydani, pocet_stran, manga_id, magazin_id)
VALUES ('Narutova druha dobrodruzstvi', 1.2, TO_DATE('2000-03-17', 'yyyy/mm/dd'), 131, 1, 2);
INSERT INTO episoda (nazev, poradove_cislo, datum_vydani, pocet_stran, manga_id, svazek_isbn)
VALUES ('Titans are having dinner', 32, TO_DATE('2010-10-19', 'yyyy/mm/dd'), 179, 2, '0012478902');
INSERT INTO episoda (nazev, poradove_cislo, datum_vydani, manga_id, svazek_isbn)
VALUES ('Mario meets Browser', 2.3, TO_DATE('2012-12-21', 'yyyy/mm/dd'), 3, 1234567890);
INSERT INTO episoda (nazev, poradove_cislo, datum_vydani, pocet_stran, manga_id, magazin_id)
VALUES ('Still under 9000', 37, TO_DATE('1997-12-13', 'yyyy/mm/dd'), 22, 4, 3);


INSERT INTO objednavka (datum, cena, stav, uzivatel_id, adresa_cp, adresa_psc)
VALUES (TO_DATE('2020-01-01', 'yyyy/mm/dd'), 487, 'prijata', 1, 1337, 23600);
INSERT INTO objednavka (datum, cena, stav, uzivatel_id, adresa_cp, adresa_psc)
VALUES (TO_DATE('2020-06-11', 'yyyy/mm/dd'), 200, 'odeslana', 2, 1337, 23600); --objednal jako darek na jinou nez svou adresu
INSERT INTO objednavka (datum, cena, stav, uzivatel_id, adresa_cp, adresa_psc)
VALUES (TO_DATE('2021-02-19', 'yyyy/mm/dd'), 2587.32, 'zaplacena', 3, 998, 42069);
INSERT INTO objednavka (datum, cena, stav, uzivatel_id, adresa_cp, adresa_psc)
VALUES (TO_DATE('2020-06-14', 'yyyy/mm/dd'), 220, 'stornovana', 2, 4271, 64300);
INSERT INTO objednavka (datum, cena, stav, uzivatel_id, adresa_cp, adresa_psc)
VALUES (TO_DATE('2020-06-15', 'yyyy/mm/dd'), 628.6, 'zaplacena', 2, 4271, 64300);


-- zde by se měl spustit trigger pro paritu generovaných id položek
INSERT INTO polozka (objednavka_id, magazin_id)
VALUES (1, 3);
INSERT INTO polozka (objednavka_id, magazin_id, mnozstvi)
VALUES (1, 2, 2);
INSERT INTO polozka (objednavka_id, svazek_isbn)
VALUES (2, '0012478902');
INSERT INTO polozka (objednavka_id, svazek_isbn, mnozstvi)
VALUES (3, 1234567890, 16);
INSERT INTO polozka (objednavka_id, magazin_id)
VALUES (3, 1);
INSERT INTO polozka (objednavka_id, magazin_id)
VALUES (4, 2);
INSERT INTO polozka (objednavka_id, magazin_id)
VALUES (5, 3);




---- Otestování správného fungování triggerů - TRIGGER (part 2/2)

-- první trigger - očekáváme id položek: 1,3,5,7,9,2,4 (jen dvě mají větší množství - mají sudé id)
SELECT
    id AS "ID polozky",
    mnozstvi
FROM polozka
ORDER BY mnozstvi;

-- druhý trigger - hesla uživatelů by něměla být viditelná jako čitelný text, jen jako vygenerovaný hash
SELECT
    jmeno,
    prijmeni,
    heslo AS "hash_hesla"
FROM uzivatel
ORDER BY jmeno;




---- Tvorba a test procedur - PROCEDURE

SET serveroutput ON;

-- První procedura vypíše kolik objednávek daný uživatel už provedl a zaplatil, kolik za všechny dohromady utratil, a průměrnou cenu jeho objednávky
-- počítají se pouze objednávky, které už byly zaplaceny a nebyly stornovány
CREATE OR REPLACE PROCEDURE uzivatel_objednavky_utrata (arg_id_uzivatele INT) AS
BEGIN
    DECLARE CURSOR kursor is
    SELECT uzv.id, uzv.jmeno, uzv.prijmeni, obj.cena
    FROM uzivatel uzv, objednavka obj
    WHERE arg_id_uzivatele = uzv.id AND uzv.id = obj.uzivatel_id AND obj.stav IN('zaplacena', 'odeslana');    
        id_uzivatele uzivatel.id%TYPE;
        jmeno_uzivatele uzivatel.jmeno%TYPE;
        prijmeni_uzivatele uzivatel.prijmeni%TYPE;
        cena_objednavky objednavka.cena%TYPE;
        suma NUMBER;
        prumer NUMBER;
        counter NUMBER;
        BEGIN
            suma := 0;
            prumer := 0;
            counter := 0;
            OPEN kursor;
            LOOP
                FETCH kursor INTO id_uzivatele, jmeno_uzivatele, prijmeni_uzivatele, cena_objednavky;
                EXIT WHEN kursor%NOTFOUND;
                suma := suma + cena_objednavky;
                counter := counter + 1;
            END LOOP;
            CLOSE kursor;
            prumer := suma / counter;
            DBMS_OUTPUT.put_line('Uzivatel ID=' || id_uzivatele || ' ' || jmeno_uzivatele || ' ' || prijmeni_uzivatele 
            || ' dokoncil celkem: ' || counter || ' objednavek, za ktere celkem zaplatil: ' || suma || ' a prumerna cena objednavky byla: ' || prumer);
            EXCEPTION WHEN ZERO_DIVIDE THEN
            BEGIN
                DBMS_OUTPUT.put_line('Vybrany uzivatel zatim nezaplatil zadnou objednavku (nepocitaje stornovane objednavky)');
            END;
         END;
END;
/
-- Test první procedury
-- První uživatel zatím svou objednávku nezaplatil, druhý již zaplatil 2 objednávky
EXEC uzivatel_objednavky_utrata(1);
EXEC uzivatel_objednavky_utrata(2);


-- Druhá procedura vypíše počet a kolik % všech zaplacených (nestornovaných) objednávek má cenu nižší nebo stejnou jako číselná hodnota předaná argumentem
CREATE OR REPLACE PROCEDURE podil_levnejsich_objednavek (arg_cena NUMBER) AS
    celkem NUMBER;
    pod_hranici NUMBER;
    podil NUMBER;
BEGIN
    SELECT COUNT(*) INTO celkem FROM objednavka obj WHERE obj.stav IN('zaplacena','stornovana');
    SELECT COUNT(*) INTO pod_hranici FROM objednavka obj WHERE obj.stav IN('zaplacena','odeslana') AND obj.cena <= arg_cena;
    podil := ROUND(100 * pod_hranici / celkem, 2);
    DBMS_OUTPUT.put_line('Ze vsech ' || celkem || ' zaplacenych objednavek je jich ' || pod_hranici || ' pod hranici '
    || arg_cena || ', coz tvori ' || podil || '% vsech zaplacenych objednavek');
    EXCEPTION WHEN ZERO_DIVIDE THEN
    BEGIN
        DBMS_OUTPUT.put_line('Zadna objednavka ulozena v systemu zatim nebyla zaplacena');
    END;
END;
/
-- Test druhé procedury
-- 1 levnejsi nez 300, 0 levnejsi nez 1, vsechny levnejsi nez 100 000
EXEC podil_levnejsich_objednavek(300);
EXEC podil_levnejsich_objednavek(1);
EXEC podil_levnejsich_objednavek(100000);




---- EXPLAIN PLAN

-- Ale ne, zavřely se české hranice! Potřebujeme o tom kontaktovat všechny zahraniční uživatele!
-- Zobrazí email, počet objednávek a stát všech uživatelů žijící mimo Českou republiku, kteří mají alespoň 1 objednávku
EXPLAIN PLAN FOR
SELECT
    uzv.email AS "Email",
    COUNT(obj.uzivatel_id) AS "Objednavky"
FROM uzivatel uzv
JOIN objednavka obj ON obj.uzivatel_id = uzv.id
JOIN adresa adr ON adr.cislo_popisne = uzv.adresa_cp AND adr.psc = uzv.adresa_psc
WHERE adr.zeme != 'Česká republika'
GROUP BY uzv.id, uzv.email
HAVING COUNT(obj.uzivatel_id) > 0
ORDER BY "Email";
-- otestovani
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- index rychle seřadí uživatele podle státu, tím se lidé z ČR seskupí a přeskočí
CREATE INDEX adresa_zeme ON adresa (zeme);

-- Test explain plan po vytvoření indexu
EXPLAIN PLAN FOR
SELECT
    uzv.email AS "Email",
    COUNT(obj.uzivatel_id) AS "Objednavky"
FROM uzivatel uzv
JOIN objednavka obj ON obj.uzivatel_id = uzv.id
JOIN adresa adr ON adr.cislo_popisne = uzv.adresa_cp AND adr.psc = uzv.adresa_psc
WHERE adr.zeme != 'Česká republika'
GROUP BY uzv.id, uzv.email
HAVING COUNT(obj.uzivatel_id) > 0
ORDER BY "Email";
-- otestovani
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
