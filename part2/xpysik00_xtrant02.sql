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
        CHECK(NOT REGEXP_LIKE(psc, '%[^0-9]%')), -- PSC ma opet fixni pocet cislic
    PRIMARY KEY(cislo_popisne, psc), --slozeny PK
    ulice VARCHAR(64) NOT NULL,
    cislo_domu INT DEFAULT NULL,
    zeme VARCHAR(64) NOT NULL,
    mesto VARCHAR(64) DEFAULT NULL
);


CREATE TABLE autor (
    ico CHAR(8) NOT NULL PRIMARY KEY
        CHECK(NOT REGEXP_LIKE(ico, '%[^0-9]%')), -- ICO osoby je osmimistne cislo bez znamenka (dekadicky, cislic musi byt vzdy 8 - proto CHAR a ne VARCHAR, INT ani NUMBER)
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
    email VARCHAR(128) NOT NULL,
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
        CHECK(NOT REGEXP_LIKE(isbn, '%[^0-9]%')), -- standard ISBN-10, NE ISBN-13
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
    CONSTRAINT neni_prazdna_polozka -- Polozka nesmi byt prazdna
        CHECK(svazek_isbn IS NOT NULL OR magazin_id IS NOT NULL),
    CONSTRAINT neni_vicenasobna_polozka -- Polozka vsak musi obsahovat bud pouze magazin, nebo pouze svazek!
        CHECK(svazek_isbn IS NULL OR magazin_id IS NULL)
);






---- Tvorba instanci (vkladani do tabulek)

