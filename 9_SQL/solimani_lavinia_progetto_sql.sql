/*
PROGETTO: ANALISI DEI CLIENTI DI UNA BANCA

di Lavinia Solimani


L'obiettivo di questo progetto è estrarre, per ogni cliente, una tabella denormalizzata di indicatori
(feature) derivati dalle tabelle disponibili nel database, che rappresentano i comportamenti e le
attività finanziarie dei clienti di una banca. In questo modo, la tabella potrà poi essere utilizzata
per l'addestramento di modelli di machine learning, arricchendo i dati dei clienti con vari indicatori
calcolati a partire dalle loro transazioni e dai conti posseduti. 

Il database è costituito dalle seguenti tabelle:
1. Cliente: contiene informazioni personali sui clienti (ad esempio, età).
2. Conto: contiene informazioni sui conti posseduti dai clienti.
3. Tipo_conto: descrive le diverse tipologie di conti disponibili.
4. Tipo_transazione: contiene i tipi di transazione che possono avvenire sui conti.
5. Transazioni: contiene i dettagli delle transazioni effettuate dai clienti sui vari conti.

Gli indicatori verranno calcolati mediante la creazione di tabelle temporanee e l'utilizzo di
operazioni di aggregazione (SUM, COUNT).
*/


DROP TEMPORARY TABLE IF EXISTS tmp_eta, tmp_transazioni, tmp_conti, tmp_trans_tipo_conto;


-- INDICATORI DI BASE

CREATE TEMPORARY TABLE tmp_eta
SELECT
	id_cliente,
    
    -- 1. Età del cliente
    TIMESTAMPDIFF(YEAR, data_nascita, CURRENT_DATE()) AS eta
FROM cliente;


-- INDICATORI SULLE TRANSAZIONI

CREATE TEMPORARY TABLE tmp_transazioni
SELECT
    co.id_cliente,
    
    -- 2. Numero di transazioni in uscita su tutti i conti
    COUNT(CASE WHEN tt.segno = '-' THEN 1 END) AS num_transazioni_uscita,

    -- 3. Numero di transazioni in entrata su tutti i conti
    COUNT(CASE WHEN tt.segno = '+' THEN 1 END) AS num_transazioni_entrata,

    -- 4. Importo totale transato in uscita su tutti i conti
    ROUND(SUM(CASE WHEN tt.segno = '-' THEN tr.importo ELSE 0 END), 2) AS tot_transazioni_uscita,

    -- 5. Importo totale transato in entrata su tutti i conti
    ROUND(SUM(CASE WHEN tt.segno = '+' THEN tr.importo ELSE 0 END), 2) AS tot_transazioni_entrata

FROM conto AS co
INNER JOIN transazioni AS tr
    ON co.id_conto = tr.id_conto
INNER JOIN tipo_transazione AS tt
    ON tr.id_tipo_trans = tt.id_tipo_transazione
GROUP BY co.id_cliente;


-- INDICATORI SUI CONTI

CREATE TEMPORARY TABLE tmp_conti
SELECT
    id_cliente,

    -- 6. Numero totale di conti posseduti
    COUNT(*) AS num_tot_conti,

    -- 7. Numero di conti posseduti per tipologia (un indicatore per ogni tipo di conto)
	COUNT(CASE WHEN id_tipo_conto = 0 THEN 1 END) AS num_conti_base,
    COUNT(CASE WHEN id_tipo_conto = 1 THEN 1 END) AS num_conti_business,
    COUNT(CASE WHEN id_tipo_conto = 2 THEN 1 END) AS num_conti_privati,
    COUNT(CASE WHEN id_tipo_conto = 3 THEN 1 END) AS num_conti_famiglie

FROM conto
GROUP BY id_cliente;


-- INDICATORI SULLE TRANSAZIONI PER TIPOLOGIA DI CONTO

CREATE TEMPORARY TABLE tmp_trans_tipo_conto
SELECT
	co.id_cliente,

    -- 8. Numero di transazioni in uscita per tipologia di conto (un indicatore per tipo di conto)
    COUNT(CASE WHEN tt.segno = '-' AND co.id_tipo_conto = 0 THEN 1 END) AS num_trans_uscita_base,
    COUNT(CASE WHEN tt.segno = '-' AND co.id_tipo_conto = 1 THEN 1 END) AS num_trans_uscita_business,
    COUNT(CASE WHEN tt.segno = '-' AND co.id_tipo_conto = 2 THEN 1 END) AS num_trans_uscita_privati,
    COUNT(CASE WHEN tt.segno = '-' AND co.id_tipo_conto = 3 THEN 1 END) AS num_trans_uscita_famiglie,

    -- 9. Numero di transazioni in entrata per tipologia di conto (un indicatore per tipo di conto)
    COUNT(CASE WHEN tt.segno = '+' AND co.id_tipo_conto = 0 THEN 1 END) AS num_trans_entrata_base,
    COUNT(CASE WHEN tt.segno = '+' AND co.id_tipo_conto = 1 THEN 1 END) AS num_trans_entrata_business,
    COUNT(CASE WHEN tt.segno = '+' AND co.id_tipo_conto = 2 THEN 1 END) AS num_trans_entrata_privati,
    COUNT(CASE WHEN tt.segno = '+' AND co.id_tipo_conto = 3 THEN 1 END) AS num_trans_entrata_famiglie,

    -- 10. Importo transato in uscita per tipologia di conto (un indicatore per tipo di conto)
    ROUND(SUM(CASE WHEN tt.segno = '-' AND co.id_tipo_conto = 0 THEN tr.importo ELSE 0 END), 2) AS tot_trans_uscita_base,
    ROUND(SUM(CASE WHEN tt.segno = '-' AND co.id_tipo_conto = 1 THEN tr.importo ELSE 0 END), 2) AS tot_trans_uscita_business,
    ROUND(SUM(CASE WHEN tt.segno = '-' AND co.id_tipo_conto = 2 THEN tr.importo ELSE 0 END), 2) AS tot_trans_uscita_privati,
    ROUND(SUM(CASE WHEN tt.segno = '-' AND co.id_tipo_conto = 3 THEN tr.importo ELSE 0 END), 2) AS tot_trans_uscita_famiglie,
 
    -- 11. Importo transato in entrata per tipologia di conto (un indicatore per tipo di conto)
    ROUND(SUM(CASE WHEN tt.segno = '+' AND co.id_tipo_conto = 0 THEN tr.importo ELSE 0 END), 2) AS tot_trans_entrata_base,
    ROUND(SUM(CASE WHEN tt.segno = '+' AND co.id_tipo_conto = 1 THEN tr.importo ELSE 0 END), 2) AS tot_trans_entrata_business,
    ROUND(SUM(CASE WHEN tt.segno = '+' AND co.id_tipo_conto = 2 THEN tr.importo ELSE 0 END), 2) AS tot_trans_entrata_privati,
    ROUND(SUM(CASE WHEN tt.segno = '+' AND co.id_tipo_conto = 3 THEN tr.importo ELSE 0 END), 2) AS tot_trans_entrata_famiglie

FROM conto AS co
INNER JOIN transazioni AS tr
	ON co.id_conto = tr.id_conto
INNER JOIN tipo_transazione AS tt
    ON tr.id_tipo_trans = tt.id_tipo_transazione
GROUP BY co.id_cliente;


/*
Procediamo con l'estrazione finale degli indicatori calcolati, partendo dal cliente
ed eseguendo una join con le tabelle temporanee create.
*/

SELECT
	cli.id_cliente,
    cli.nome,
    cli.cognome,
    cli.data_nascita,

    -- Indicatori di base
    e.eta,

    -- Indicatori sulle transazioni
    COALESCE(tr.num_transazioni_uscita, 0) AS num_transazioni_uscita,
    COALESCE(tr.num_transazioni_entrata, 0) AS num_transazioni_entrata,
    COALESCE(tr.tot_transazioni_uscita, 0) AS tot_transazioni_uscita,
    COALESCE(tr.tot_transazioni_entrata, 0) AS tot_transazioni_entrata,

    -- Indicatori sui conti
    COALESCE(co.num_tot_conti, 0) AS num_tot_conti,
    COALESCE(co.num_conti_base, 0) AS num_conti_base,
    COALESCE(co.num_conti_business, 0) AS num_conti_business,
    COALESCE(co.num_conti_privati, 0) AS num_conti_privati,
    COALESCE(co.num_conti_famiglie, 0) AS num_conti_famiglie,

    -- Indicatori sulle transazioni per tipologia di conto
    COALESCE(tc.num_trans_uscita_base, 0) AS num_trans_uscita_base,
    COALESCE(tc.num_trans_uscita_business, 0) AS num_trans_uscita_business,
    COALESCE(tc.num_trans_uscita_privati, 0) AS num_trans_uscita_privati,
    COALESCE(tc.num_trans_uscita_famiglie, 0) AS num_trans_uscita_famiglie,

    COALESCE(tc.num_trans_entrata_base, 0) AS num_trans_entrata_base,
    COALESCE(tc.num_trans_entrata_business, 0) AS num_trans_entrata_business,
    COALESCE(tc.num_trans_entrata_privati, 0) AS num_trans_entrata_privati,
    COALESCE(tc.num_trans_entrata_famiglie, 0) AS num_trans_entrata_famiglie,

    COALESCE(tc.tot_trans_uscita_base, 0) AS tot_trans_uscita_base,
    COALESCE(tc.tot_trans_uscita_business, 0) AS tot_trans_uscita_business,
    COALESCE(tc.tot_trans_uscita_privati, 0) AS tot_trans_uscita_privati,
    COALESCE(tc.tot_trans_uscita_famiglie, 0) AS tot_trans_uscita_famiglie,

    COALESCE(tc.tot_trans_entrata_base, 0) AS tot_trans_entrata_base,
    COALESCE(tc.tot_trans_entrata_business, 0) AS tot_trans_entrata_business,
    COALESCE(tc.tot_trans_entrata_privati, 0) AS tot_trans_entrata_privati,
    COALESCE(tc.tot_trans_entrata_famiglie, 0) AS tot_trans_entrata_famiglie

FROM cliente AS cli
LEFT JOIN tmp_eta AS e
    ON cli.id_cliente = e.id_cliente
LEFT JOIN tmp_transazioni AS tr
    ON cli.id_cliente = tr.id_cliente
LEFT JOIN tmp_conti AS co
    ON cli.id_cliente = co.id_cliente
LEFT JOIN tmp_trans_tipo_conto AS tc
	ON cli.id_cliente = tc.id_cliente
ORDER BY cli.id_cliente;


/*
Ora eseguiamo alcune query di controllo sui valori calcolati dagli indicatori,
rispetto ai dati contenuti nelle tabelle originali.
N.B. le eventuali differenze tra gli importi, nell'ordine dei centesimi,
sono dovute al fatto che per calcolare gli indicatori è stato applicato
l'arrotondamento.
*/

-- Assenza di valori anomali relativi all'età dei clienti
SELECT
	MIN(eta) AS eta_min,
	MAX(eta) AS eta_max,
	SUM(eta IS NULL) AS eta_null
FROM tmp_eta;


-- Assenza di NULL
SELECT * FROM tmp_transazioni
WHERE num_transazioni_uscita IS NULL
	OR num_transazioni_entrata IS NULL
	OR tot_transazioni_uscita IS NULL
	OR tot_transazioni_entrata IS NULL;

SELECT * FROM tmp_conti
WHERE num_tot_conti IS NULL;


-- Conteggio e totale delle transazioni
SELECT
   (SELECT COUNT(*) FROM transazioni) AS num_transazioni_db,
   SUM(num_transazioni_uscita + num_transazioni_entrata) AS num_transazioni_indicatori,
   (SELECT ROUND(SUM(importo), 2) FROM transazioni) AS importo_tot_db,
   ROUND(SUM(tot_transazioni_uscita + tot_transazioni_entrata), 2) AS importo_tot_indicatori
FROM tmp_transazioni;


-- Conteggio dei conti associati ai clienti
SELECT
	(SELECT COUNT(*) FROM conto) AS tot_conti_db,
	SUM(num_tot_conti) AS tot_conti_indicatori
FROM tmp_conti;


-- Importi totali di entrate e uscite
WITH
tot_indicatori AS (
	SELECT
		ROUND(SUM(tot_transazioni_entrata), 2) AS entrate_indicatori,
        ROUND(SUM(tot_transazioni_uscita), 2) AS uscite_indicatori
	FROM tmp_transazioni
),
tot_db AS (
	SELECT
		ROUND(SUM(CASE WHEN tt.segno = '+' THEN tr.importo ELSE 0 END), 2) AS entrate_db,
		ROUND(SUM(CASE WHEN tt.segno = '-' THEN tr.importo ELSE 0 END), 2) AS uscite_db
	FROM transazioni AS tr
	INNER JOIN tipo_transazione AS tt
		ON tr.id_tipo_trans = tt.id_tipo_transazione
)
SELECT
	db.entrate_db,
    db.uscite_db,
    ind.entrate_indicatori,
	ind.uscite_indicatori
FROM tot_db AS db, tot_indicatori AS ind;


-- Clienti senza conti o transazioni
SELECT
	SUM(co.id_cliente IS NULL) AS clienti_senza_conti,
	SUM(tr.id_cliente IS NULL) AS clienti_senza_transazioni
FROM cliente AS cli
LEFT JOIN tmp_conti AS co
	ON cli.id_cliente = co.id_cliente
LEFT JOIN tmp_transazioni AS tr
	ON cli.id_cliente = tr.id_cliente;


-- Coerenza nella somma delle tipologie di conti
SELECT id_cliente
FROM tmp_conti
WHERE num_tot_conti != 
	(num_conti_base + num_conti_business + num_conti_privati + num_conti_famiglie);