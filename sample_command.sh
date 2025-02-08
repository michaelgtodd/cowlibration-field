#!/bin/bash

FieldCalibrator                                                      \
    --input-dir data/input_champs_blue/                              \
    --camera-model data/camera_models/iphone_12_with_correction.json \
    --ideal-map data/field_maps/2024-crescendo.json                  \
    --output-file output.json                                        \
    --fps 15                                                         \
    --tag-size 0.1651                                                \
    --pin-tag 7

python3 ./scripts/visualize.py ./data/field_maps/2024-crescendo.json ./output.json