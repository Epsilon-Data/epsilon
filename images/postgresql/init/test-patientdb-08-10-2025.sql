--
-- PostgreSQL database dump
--

-- Dumped from database version 15.10
-- Dumped by pg_dump version 17.0 (DBngin.app)

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

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: examination; Type: TABLE; Schema: public; Owner: test_admin
--

CREATE TABLE public.examination (
    blood_pressure character varying,
    heart_rate integer,
    date time with time zone NOT NULL,
    stable boolean,
    patient_id integer NOT NULL
);


ALTER TABLE public.examination OWNER TO test_admin;

--
-- Name: patient; Type: TABLE; Schema: public; Owner: test_admin
--

CREATE TABLE public.patient (
    patient_id integer NOT NULL,
    age integer,
    medications character varying[],
    admission_date time with time zone,
    diagnosis character varying,
    critical boolean
);


ALTER TABLE public.patient OWNER TO test_admin;

--
-- Data for Name: examination; Type: TABLE DATA; Schema: public; Owner: test_admin
--

COPY public.patient (patient_id, age, medications, admission_date, diagnosis, critical) FROM stdin;
1	67	{Lisinopril,Atorvastatin}	2025-10-12 09:15:00+00	Hypertension	false
2	54	{Metformin}	2025-11-03 14:20:00+00	Type 2 Diabetes	false
3	78	{Amlodipine,Warfarin}	2025-09-28 08:45:00+00	Atrial Fibrillation	true
4	34	{Salbutamol}	2025-12-01 11:10:00+00	Asthma	false
5	82	{Furosemide,Lisinopril}	2025-10-05 06:30:00+00	Heart Failure	true
6	61	{Aspirin,Atorvastatin}	2025-11-18 13:05:00+00	Coronary Artery Disease	false
7	45	{Sertraline}	2025-12-10 10:00:00+00	Depression	false
8	70	{Donepezil}	2025-09-20 16:40:00+00	Dementia	false
9	29	{Levetiracetam}	2025-12-15 21:00:00+00	Epilepsy	false
10	88	{Morphine}	2025-08-30 04:55:00+00	Palliative Care	true
11	52	{Metoprolol}	2025-11-08 09:00:00+00	Hypertension	false
12	64	{Insulin}	2025-10-22 12:10:00+00	Type 1 Diabetes	false
13	71	{Clopidogrel}	2025-09-18 07:50:00+00	Stroke	false
14	39	{Ibuprofen}	2025-12-05 15:30:00+00	Musculoskeletal Pain	false
15	76	{Bisoprolol}	2025-09-10 08:20:00+00	Heart Failure	true
16	58	{Omeprazole}	2025-11-21 11:45:00+00	Gastritis	false
17	66	{Allopurinol}	2025-10-02 09:40:00+00	Gout	false
18	47	{Fluoxetine}	2025-12-03 13:15:00+00	Anxiety	false
19	81	{Furosemide}	2025-09-14 06:10:00+00	Renal Failure	true
20	60	{Losartan}	2025-11-27 10:35:00+00	Hypertension	false
21	33	{Salbutamol}	2025-12-12 18:20:00+00	Asthma	false
22	74	{Warfarin}	2025-09-08 07:00:00+00	Pulmonary Embolism	true
23	56	{Metformin,Atorvastatin}	2025-10-30 09:50:00+00	Metabolic Syndrome	false
24	69	{Donepezil}	2025-09-22 16:10:00+00	Alzheimer's Disease	false
25	42	{Prednisolone}	2025-12-06 14:40:00+00	Autoimmune Disorder	false
26	85	{Morphine,Midazolam}	2025-08-25 05:20:00+00	End of Life	true
27	59	{Metoprolol}	2025-11-15 08:55:00+00	Arrhythmia	false
28	63	{Aspirin}	2025-10-18 10:25:00+00	Ischaemic Heart Disease	false
29	48	{Gabapentin}	2025-12-02 12:00:00+00	Neuropathic Pain	false
30	72	{Levodopa}	2025-09-05 09:35:00+00	Parkinson's Disease	false
31	65	{Lisinopril}	2025-10-14 08:10:00+00	Hypertension	false
32	50	{Metformin}	2025-11-06 14:30:00+00	Type 2 Diabetes	false
33	79	{Warfarin}	2025-09-26 07:55:00+00	Valve Replacement	true
34	36	{Paracetamol}	2025-12-07 16:00:00+00	Headache	false
35	83	{Furosemide}	2025-09-12 06:45:00+00	Heart Failure	true
36	57	{Atorvastatin}	2025-11-19 13:40:00+00	Hyperlipidaemia	false
37	44	{Sertraline}	2025-12-09 10:10:00+00	Depression	false
38	71	{Donepezil}	2025-09-24 15:50:00+00	Dementia	false
39	27	{Levetiracetam}	2025-12-14 20:30:00+00	Epilepsy	false
40	90	{Morphine}	2025-08-28 03:45:00+00	Palliative Care	true
41	62	{Metoprolol}	2025-11-10 09:25:00+00	Hypertension	false
42	68	{Insulin}	2025-10-20 11:55:00+00	Type 1 Diabetes	false
43	75	{Clopidogrel}	2025-09-16 08:05:00+00	Stroke	false
44	40	{Ibuprofen}	2025-12-04 15:20:00+00	Musculoskeletal Pain	false
45	78	{Bisoprolol}	2025-09-09 08:30:00+00	Heart Failure	true
46	55	{Omeprazole}	2025-11-22 12:10:00+00	Gastritis	false
47	67	{Allopurinol}	2025-10-01 09:15:00+00	Gout	false
48	49	{Fluoxetine}	2025-12-02 13:35:00+00	Anxiety	false
49	82	{Furosemide}	2025-09-13 06:25:00+00	Renal Failure	true
50	61	{Losartan}	2025-11-26 10:50:00+00	Hypertension	false
51	35	{Salbutamol}	2025-12-11 18:05:00+00	Asthma	false
52	73	{Warfarin}	2025-09-07 07:15:00+00	Pulmonary Embolism	true
53	58	{Metformin,Atorvastatin}	2025-10-29 09:40:00+00	Metabolic Syndrome	false
54	70	{Donepezil}	2025-09-23 16:00:00+00	Alzheimer's Disease	false
55	43	{Prednisolone}	2025-12-05 14:55:00+00	Autoimmune Disorder	false
56	86	{Morphine,Midazolam}	2025-08-24 05:10:00+00	End of Life	true
57	60	{Metoprolol}	2025-11-14 08:40:00+00	Arrhythmia	false
58	64	{Aspirin}	2025-10-17 10:10:00+00	Ischaemic Heart Disease	false
59	46	{Gabapentin}	2025-12-01 11:50:00+00	Neuropathic Pain	false
60	74	{Levodopa}	2025-09-04 09:20:00+00	Parkinson's Disease	false
61	66	{Lisinopril}	2025-10-13 08:25:00+00	Hypertension	false
62	51	{Metformin}	2025-11-05 14:45:00+00	Type 2 Diabetes	false
63	80	{Warfarin}	2025-09-27 07:40:00+00	Valve Replacement	true
64	38	{Paracetamol}	2025-12-08 16:15:00+00	Headache	false
65	84	{Furosemide}	2025-09-11 06:35:00+00	Heart Failure	true
66	56	{Atorvastatin}	2025-11-20 13:55:00+00	Hyperlipidaemia	false
67	41	{Sertraline}	2025-12-10 10:25:00+00	Depression	false
68	72	{Donepezil}	2025-09-25 15:35:00+00	Dementia	false
69	28	{Levetiracetam}	2025-12-13 20:45:00+00	Epilepsy	false
70	91	{Morphine}	2025-08-27 03:30:00+00	Palliative Care	true
71	63	{Metoprolol}	2025-11-09 09:40:00+00	Hypertension	false
72	69	{Insulin}	2025-10-21 12:25:00+00	Type 1 Diabetes	false
73	76	{Clopidogrel}	2025-09-17 08:20:00+00	Stroke	false
74	37	{Ibuprofen}	2025-12-06 15:45:00+00	Musculoskeletal Pain	false
75	79	{Bisoprolol}	2025-09-08 08:45:00+00	Heart Failure	true
76	54	{Omeprazole}	2025-11-23 12:25:00+00	Gastritis	false
77	68	{Allopurinol}	2025-10-03 09:30:00+00	Gout	false
78	50	{Fluoxetine}	2025-12-03 13:50:00+00	Anxiety	false
79	83	{Furosemide}	2025-09-15 06:40:00+00	Renal Failure	true
80	62	{Losartan}	2025-11-28 11:05:00+00	Hypertension	false
81	34	{Salbutamol}	2025-12-13 18:35:00+00	Asthma	false
82	75	{Warfarin}	2025-09-09 07:30:00+00	Pulmonary Embolism	true
83	57	{Metformin,Atorvastatin}	2025-10-31 10:05:00+00	Metabolic Syndrome	false
84	71	{Donepezil}	2025-09-21 16:25:00+00	Alzheimer's Disease	false
85	44	{Prednisolone}	2025-12-07 15:10:00+00	Autoimmune Disorder	false
86	87	{Morphine,Midazolam}	2025-08-26 05:00:00+00	End of Life	true
87	61	{Metoprolol}	2025-11-16 09:10:00+00	Arrhythmia	false
88	65	{Aspirin}	2025-10-19 10:40:00+00	Ischaemic Heart Disease	false
89	47	{Gabapentin}	2025-12-02 12:15:00+00	Neuropathic Pain	false
90	73	{Levodopa}	2025-09-06 09:05:00+00	Parkinson's Disease	false
91	67	{Lisinopril}	2025-10-15 08:00:00+00	Hypertension	false
92	53	{Metformin}	2025-11-07 14:10:00+00	Type 2 Diabetes	false
93	81	{Warfarin}	2025-09-29 07:25:00+00	Valve Replacement	true
94	35	{Paracetamol}	2025-12-09 16:30:00+00	Headache	false
95	85	{Furosemide}	2025-09-13 06:20:00+00	Heart Failure	true
96	59	{Atorvastatin}	2025-11-21 14:05:00+00	Hyperlipidaemia	false
97	42	{Sertraline}	2025-12-11 10:40:00+00	Depression	false
98	73	{Donepezil}	2025-09-26 15:20:00+00	Dementia	false
99	26	{Levetiracetam}	2025-12-14 21:15:00+00	Epilepsy	false
100	92	{Morphine}	2025-08-29 03:15:00+00	Palliative Care	true
101	64	{Metoprolol}	2025-11-12 09:55:00+00	Hypertension	false
102	70	{Insulin}	2025-10-23 12:40:00+00	Type 1 Diabetes	false
103	77	{Clopidogrel}	2025-09-19 08:35:00+00	Stroke	false
104	39	{Ibuprofen}	2025-12-08 15:00:00+00	Musculoskeletal Pain	false
105	80	{Bisoprolol}	2025-09-10 09:00:00+00	Heart Failure	true
106	55	{Omeprazole}	2025-11-24 12:40:00+00	Gastritis	false
107	69	{Allopurinol}	2025-10-04 09:45:00+00	Gout	false
108	51	{Fluoxetine}	2025-12-04 14:05:00+00	Anxiety	false
109	84	{Furosemide}	2025-09-16 06:55:00+00	Renal Failure	true
110	63	{Losartan}	2025-11-29 11:20:00+00	Hypertension	false
111	36	{Salbutamol}	2025-12-14 18:50:00+00	Asthma	false
112	76	{Warfarin}	2025-09-10 07:45:00+00	Pulmonary Embolism	true
113	58	{Metformin,Atorvastatin}	2025-11-01 10:20:00+00	Metabolic Syndrome	false
114	72	{Donepezil}	2025-09-22 16:50:00+00	Alzheimer's Disease	false
115	45	{Prednisolone}	2025-12-08 15:25:00+00	Autoimmune Disorder	false
116	88	{Morphine,Midazolam}	2025-08-31 05:30:00+00	End of Life	true
117	62	{Metoprolol}	2025-11-17 09:25:00+00	Arrhythmia	false
118	66	{Aspirin}	2025-10-20 11:10:00+00	Ischaemic Heart Disease	false
119	48	{Gabapentin}	2025-12-03 12:30:00+00	Neuropathic Pain	false
120	74	{Levodopa}	2025-09-07 09:50:00+00	Parkinson's Disease	false
\.


--
-- Data for Name: patient; Type: TABLE DATA; Schema: public; Owner: test_admin
--

COPY public.examination (blood_pressure, heart_rate, date, stable, patient_id) FROM stdin;
120/80	72	2025-10-12 10:00:00+00	true	1
118/78	70	2025-10-13 10:00:00+00	true	1
135/88	85	2025-11-03 16:00:00+00	true	2
138/90	88	2025-11-04 09:30:00+00	false	2
155/95	110	2025-09-28 10:15:00+00	false	3
150/92	108	2025-09-29 09:00:00+00	false	3
125/82	78	2025-12-01 13:00:00+00	true	4
122/80	76	2025-12-02 13:10:00+00	true	4
160/100	115	2025-10-05 07:15:00+00	false	5
158/98	112	2025-10-06 07:30:00+00	false	5
130/85	82	2025-11-18 14:00:00+00	true	6
128/82	80	2025-11-19 14:10:00+00	true	6
118/75	74	2025-12-10 11:00:00+00	true	7
120/76	75	2025-12-11 11:10:00+00	true	7
132/84	78	2025-09-20 17:00:00+00	true	8
135/86	80	2025-09-21 17:15:00+00	true	8
110/70	72	2025-12-15 22:00:00+00	true	9
112/72	74	2025-12-16 22:10:00+00	true	9
92/60	98	2025-08-30 06:00:00+00	false	10
90/58	102	2025-08-31 06:10:00+00	false	10
128/82	78	2025-11-08 10:00:00+00	true	11
130/84	80	2025-11-09 10:10:00+00	true	11
140/90	88	2025-10-22 13:00:00+00	true	12
138/88	86	2025-10-23 13:10:00+00	true	12
150/95	105	2025-09-18 09:00:00+00	false	13
148/92	102	2025-09-19 09:10:00+00	false	13
122/78	76	2025-12-05 16:00:00+00	true	14
124/80	78	2025-12-06 16:10:00+00	true	14
158/96	110	2025-09-10 09:00:00+00	false	15
155/94	108	2025-09-11 09:10:00+00	false	15
118/74	72	2025-11-21 12:30:00+00	true	16
120/76	74	2025-11-22 12:40:00+00	true	16
130/84	80	2025-10-02 10:30:00+00	true	17
132/86	82	2025-10-03 10:40:00+00	true	17
122/78	76	2025-12-03 14:00:00+00	true	18
124/80	78	2025-12-04 14:10:00+00	true	18
95/62	100	2025-09-14 07:00:00+00	false	19
98/64	102	2025-09-15 07:10:00+00	false	19
126/80	78	2025-11-27 11:30:00+00	true	20
128/82	80	2025-11-28 11:40:00+00	true	20
120/78	76	2025-12-12 19:00:00+00	true	21
122/80	78	2025-12-13 19:10:00+00	true	21
150/95	108	2025-09-08 08:00:00+00	false	22
148/92	105	2025-09-09 08:10:00+00	false	22
132/86	82	2025-10-30 10:30:00+00	true	23
130/84	80	2025-10-31 10:40:00+00	true	23
128/82	78	2025-09-22 17:00:00+00	true	24
130/84	80	2025-09-23 17:10:00+00	true	24
124/80	78	2025-12-06 15:30:00+00	true	25
126/82	80	2025-12-07 15:40:00+00	true	25
90/58	104	2025-08-25 06:00:00+00	false	26
88/56	106	2025-08-26 06:10:00+00	false	26
130/84	80	2025-11-15 09:30:00+00	true	27
132/86	82	2025-11-16 09:40:00+00	true	27
128/82	78	2025-10-18 11:00:00+00	true	28
130/84	80	2025-10-19 11:10:00+00	true	28
122/78	76	2025-12-02 13:00:00+00	true	29
124/80	78	2025-12-03 13:10:00+00	true	29
135/88	82	2025-09-05 10:00:00+00	true	30
138/90	84	2025-09-06 10:10:00+00	true	30
130/84	80	2025-10-14 09:00:00+00	true	31
132/86	82	2025-10-15 09:10:00+00	true	31
138/90	86	2025-11-06 15:00:00+00	true	32
140/92	88	2025-11-07 15:10:00+00	true	32
150/96	108	2025-09-26 08:30:00+00	false	33
148/94	105	2025-09-27 08:40:00+00	false	33
120/76	74	2025-12-07 17:00:00+00	true	34
122/78	76	2025-12-08 17:10:00+00	true	34
158/98	112	2025-09-12 07:30:00+00	false	35
155/96	110	2025-09-13 07:40:00+00	false	35
132/86	82	2025-11-19 14:30:00+00	true	36
130/84	80	2025-11-20 14:40:00+00	true	36
120/78	76	2025-12-09 11:00:00+00	true	37
122/80	78	2025-12-10 11:10:00+00	true	37
128/82	78	2025-09-24 16:30:00+00	true	38
130/84	80	2025-09-25 16:40:00+00	true	38
110/72	74	2025-12-14 21:00:00+00	true	39
112/74	76	2025-12-15 21:10:00+00	true	39
90/56	108	2025-08-28 05:00:00+00	false	40
88/54	110	2025-08-29 05:10:00+00	false	40
130/84	80	2025-11-10 10:00:00+00	true	41
132/86	82	2025-11-11 10:10:00+00	true	41
138/90	86	2025-10-20 13:30:00+00	true	42
140/92	88	2025-10-21 13:40:00+00	true	42
150/95	106	2025-09-16 09:00:00+00	false	43
148/92	104	2025-09-17 09:10:00+00	false	43
122/78	76	2025-12-04 16:00:00+00	true	44
124/80	78	2025-12-05 16:10:00+00	true	44
158/98	110	2025-09-09 09:30:00+00	false	45
155/96	108	2025-09-10 09:40:00+00	false	45
120/76	74	2025-11-22 13:00:00+00	true	46
122/78	76	2025-11-23 13:10:00+00	true	46
130/84	80	2025-10-01 10:00:00+00	true	47
132/86	82	2025-10-02 10:10:00+00	true	47
122/78	76	2025-12-02 14:00:00+00	true	48
124/80	78	2025-12-03 14:10:00+00	true	48
95/62	102	2025-09-13 07:00:00+00	false	49
98/64	104	2025-09-14 07:10:00+00	false	49
126/80	78	2025-11-26 11:30:00+00	true	50
128/82	80	2025-11-27 11:40:00+00	true	50
120/78	76	2025-12-11 19:00:00+00	true	51
122/80	78	2025-12-12 19:10:00+00	true	51
150/95	108	2025-09-07 08:00:00+00	false	52
148/92	105	2025-09-08 08:10:00+00	false	52
132/86	82	2025-10-29 10:30:00+00	true	53
130/84	80	2025-10-30 10:40:00+00	true	53
128/82	78	2025-09-23 17:00:00+00	true	54
130/84	80	2025-09-24 17:10:00+00	true	54
124/80	78	2025-12-05 15:30:00+00	true	55
126/82	80	2025-12-06 15:40:00+00	true	55
90/58	104	2025-08-24 06:00:00+00	false	56
88/56	106	2025-08-25 06:10:00+00	false	56
130/84	80	2025-11-14 09:30:00+00	true	57
132/86	82	2025-11-15 09:40:00+00	true	57
128/82	78	2025-10-17 11:00:00+00	true	58
130/84	80	2025-10-18 11:10:00+00	true	58
122/78	76	2025-12-01 13:00:00+00	true	59
124/80	78	2025-12-02 13:10:00+00	true	59
135/88	82	2025-09-04 10:00:00+00	true	60
138/90	84	2025-09-05 10:10:00+00	true	60
\.

--
-- Name: examination examination_pkey; Type: CONSTRAINT; Schema: public; Owner: test_admin
--

ALTER TABLE ONLY public.examination
    ADD CONSTRAINT examination_pkey PRIMARY KEY (patient_id, date);


--
-- Name: patient patient_pkey; Type: CONSTRAINT; Schema: public; Owner: test_admin
--

ALTER TABLE ONLY public.patient
    ADD CONSTRAINT patient_pkey PRIMARY KEY (patient_id);


--
-- Name: examination fk_patient; Type: FK CONSTRAINT; Schema: public; Owner: test_admin
--

ALTER TABLE ONLY public.examination
    ADD CONSTRAINT fk_patient FOREIGN KEY (patient_id) REFERENCES public.patient(patient_id);


--
-- PostgreSQL database dump complete
--