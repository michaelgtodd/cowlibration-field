#!/bin/bash

FieldCalibrator \
    --input-dir ./data/input_champs_blue/  \
    --output-file output.txt  \
    --camera-model ./data/camera_models/iphone_12_with_correction.json  \
    --ideal-map ./data/field_maps/2024-crescendo.json  \
    --pin-tag 1