

# ENA Bracken results metadata Registry Service

## Usage

All metadata API responses will have the form

```json
{
    "data": "content of the response",
    "message": "Description of what happened"
}
```

Following responses and definitions will only show the expected value of the data field

### Retrieve metadata associated to run accessions

**Definition**

**`GET /fetchmetadata`**

-**`run_accession`** : `sequence reads accession`

-**`top:`**: `Top n species with best fraction total reads coverage per hits (run_accession)`

**Arguments**

```json
{
  {"run_accession": ["ERR4025298|ERR4025300|ERR4025297|ERR4025298"],"top":"1" }
}
```


**Response**

- `200 OK` on success

```json
{
    "data": [
        {
            "added_reads": 26070,
            "fraction_total_reads": 0.99863,
            "kraken_assigned_reads": 1097463,
            "name": "Salmonella enterica",
            "new_est_reads": 1123533,
            "run_accession": "ERR4025297",
            "taxonomy_id": 28901
        },
        {
            "added_reads": 24518,
            "fraction_total_reads": 0.98853,
            "kraken_assigned_reads": 1293161,
            "name": "Salmonella enterica",
            "new_est_reads": 1317679,
            "run_accession": "ERR4025298",
            "taxonomy_id": 28901
        },
        {
            "added_reads": 22059,
            "fraction_total_reads": 0.99077,
            "kraken_assigned_reads": 1191343,
            "name": "Salmonella enterica",
            "new_est_reads": 1213402,
            "run_accession": "ERR4025300",
            "taxonomy_id": 28901
        }
    ]
}
```

- `404` Not found

```json
{
    "message": "run accession not found",
    "data": {}
}
```

### Queried postgreSQL dump 

```
database/ena_bracken.sql.gz
```
