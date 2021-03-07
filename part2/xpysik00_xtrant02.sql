-- IDS Projekt část 2 - SQL skript pro vytvoření základních objektů databáze
-- Autor: Michal Pyšík (login: xpysik00)
-- Autor: Michal Tran (login: xtrant02)




---- Smazani tabulek vytvorenych pri predeslem spusteni skriptu

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




---- Tvorba novych tabulek

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
    datum_narozeni DATE NOT NULL, -- musi uvest, napriklad male dite si nesmi nic objednavat
    telefon NUMBER(14) NOT NULL, -- az 9 cislic + pripadny prefix (+420 zapiseme jako 00420) -> 5 + 9 = 14 cislic
    email VARCHAR(128) NOT NULL
        CHECK(REGEXP_LIKE(email, '^[a-z][a-z0-9_\.-]*@[a-z0-9_\.-]+\.[a-z]{2,}$', 'i')),
    adresa_cp INTEGER NOT NULL,
    adresa_psc CHAR(5) NOT NULL,
    CONSTRAINT bydli_na_adrese_cp_psc_fk
        FOREIGN KEY (adresa_cp, adresa_psc) REFERENCES adresa (cislo_popisne, psc)
        ON DELETE CASCADE
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
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
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
    mnozstvi INT DEFAULT 1,
    CONSTRAINT neni_prazdna_polozka -- Polozka nesmi byt prazdna
        CHECK(svazek_isbn IS NOT NULL OR magazin_id IS NOT NULL),
    CONSTRAINT neni_vicenasobna_polozka -- Polozka vsak musi obsahovat bud pouze magazin, nebo pouze svazek!
        CHECK(svazek_isbn IS NULL OR magazin_id IS NULL)
);




---- Tvorba instanci (vkladani do tabulek)

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


INSERT INTO uzivatel (jmeno, prijmeni, datum_narozeni, telefon, email, adresa_cp, adresa_psc)
VALUES ('Carl', 'Johnson', TO_DATE('1962-03-09', 'yyyy/mm/dd'), 34645501111, 'CJ_straight-busta@grove.family.com', 1337, 23600);
INSERT INTO uzivatel (jmeno, prijmeni, datum_narozeni, telefon, email, adresa_cp, adresa_psc)
VALUES ('Martin', 'Dobrak', TO_DATE('2001-11-13', 'yyyy/mm/dd'), '00420773516991', 'martus322@seznam.cz', 4271, 64300);
INSERT INTO uzivatel (jmeno, prijmeni, datum_narozeni, telefon, email, adresa_cp, adresa_psc)
VALUES ('Linus', 'Sebastian', TO_DATE('1986-03-21', 'yyyy/mm/dd'), 456987123, 'linusTechTips@ltt-store.com', 998, 42069);


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
VALUES ('Mario meets Browser', 2.3, TO_DATE('2012-12-21', 'yyyy/mm/dd'), 2, 1234567890);
INSERT INTO episoda (nazev, poradove_cislo, datum_vydani, pocet_stran, manga_id, magazin_id)
VALUES ('Still under 9000', 37, TO_DATE('1997-12-13', 'yyyy/mm/dd'), 22, 4, 3);


INSERT INTO objednavka (datum, cena, stav, uzivatel_id, adresa_cp, adresa_psc)
VALUES (TO_DATE('2020-01-01', 'yyyy/mm/dd'), 487, 'prijata', 1, 1337, 23600);
INSERT INTO objednavka (datum, cena, stav, uzivatel_id, adresa_cp, adresa_psc)
VALUES (TO_DATE('2020-06-11', 'yyyy/mm/dd'), 200, 'odeslana', 2, 1337, 23600); --objednal jako darek na jinou nez svou adresu
INSERT INTO objednavka (datum, cena, stav, uzivatel_id, adresa_cp, adresa_psc)
VALUES (TO_DATE('2021-02-19', 'yyyy/mm/dd'), 2587.32, 'zaplacena', 3, 998, 42069);


INSERT INTO polozka (objednavka_id, magazin_id)
VALUES (1, 3);
INSERT INTO polozka (objednavka_id, magazin_id)
VALUES (1, 2);
INSERT INTO polozka (objednavka_id, svazek_isbn)
VALUES (2, '0012478902');
INSERT INTO polozka (objednavka_id, svazek_isbn, mnozstvi)
VALUES (3, 1234567890, 16);
INSERT INTO polozka (objednavka_id, magazin_id)
VALUES (3, 1);











