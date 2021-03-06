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




---- Tvorba novych tabulek

CREATE TABLE autor (
    ico CHAR(8) NOT NULL PRIMARY KEY
        CHECK(NOT REGEXP_LIKE(ico, '%[^0-9]%')), -- ICO osoby je osmimistne cislo bez znamenka (dekadicky, cislic musi byt vzdy 8 - proto CHAR a ne VARCHAR, INT ani NUMBER)
    jmeno VARCHAR(64) NOT NULL,
    prijmeni VARCHAR(64) NOT NULL,
    datum_narozeni DATE DEFAULT NULL,
    bydliste VARCHAR(128) DEFAULT NULL -- pozor: bydliste neni nutne adresa, ani nemusi byt uvedeno
);


CREATE TABLE uzivatel (
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    jmeno VARCHAR(64) NOT NULL,
    prijmeni VARCHAR(64) NOT NULL,
    datum_narozeni DATE NOT NULL, -- musi uvest, napriklad male dite si nesmi nic objednavat
    telefon NUMBER(14) NOT NULL, -- az 9 cislic + pripadny prefix (+420 zapiseme jako 00420) -> 5 + 9 = 14 cislic
    email VARCHAR(128) NOT NULL
        CHECK(REGEXP_LIKE(email, '^[a-z][a-z0-9\._-]*@[a-z0-9\._-]+\.[a-z][a-z]$', 'i'))
);


CREATE TABLE manga (
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    nazev VARCHAR(128) NOT NULL,
    zacatek_vydavani DATE NOT NULL,
    konec_vydavani DATE DEFAULT NULL --konec nemusi byt uveden pokud je manga stale vydavana
);


CREATE TABLE zanr (
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    nazev VARCHAR(128) NOT NULL
);


CREATE TABLE vydavatelstvi (
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    nazev VARCHAR(128) NOT NULL
);


CREATE TABLE episoda (
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    nazev VARCHAR(128) NOT NULL,
    poradove_cislo NUMBER(8, 2) NOT NULL, -- az 2 desetinne cislice, napriklad cislo 2.3 je validni
    datum_vydani DATE NOT NULL,
    pocet_stran INT DEFAULT NULL
);


CREATE TABLE magazin (
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    nazev VARCHAR(128) NOT NULL,
    datum_vydani DATE NOT NULL,
    cena NUMBER(10, 2) NOT NULL --v mnoha menach se udava cena i s 2 desetinnymi misty
);


CREATE TABLE svazek (
    isbn CHAR(10) NOT NULL PRIMARY KEY
        CHECK(NOT REGEXP_LIKE(isbn, '%[^0-9]%')), -- standard ISBN-10, NE ISBN-13
    poradove_cislo NUMBER(8, 2) NOT NULL,
    datum_vydani DATE NOT NULL,
    pocet_stran INT DEFAULT NULL,
    cena NUMBER(10, 2) NOT NULL
);


CREATE TABLE objednavka (
    id INT GENERATED AS IDENTITY NOT NULL PRIMARY KEY,
    datum DATE NOT NULL,
    cena NUMBER(10, 2) NOT NULL,
    stav VARCHAR(12) NOT NULL
        CHECK(stav IN('prijata', 'zaplacena', 'odeslana', 'stornovana'))
);


CREATE TABLE adresa (
    cislo_popisne INTEGER NOT NULL,
    psc CHAR(5) NOT NULL
        CHECK(NOT REGEXP_LIKE(psc, '%[^0-9]%')), -- PSC ma opet fixni pocet cislic
    PRIMARY KEY(cislo_popisne, psc),
    ulice VARCHAR(64) NOT NULL,
    cislo_domu INT DEFAULT NULL,
    zeme VARCHAR(64) NOT NULL,
    mesto VARCHAR(64) DEFAULT NULL
);




---- Tvorba instanci (vkladani do tabulek)

