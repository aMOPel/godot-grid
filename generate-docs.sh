#!/bin/bash
pushd docs

docker run --rm -v $HOME/Documents/godot_projects/godot-grid:/game -v $HOME/Documents/godot_projects/godot-grid/docs:/output gdquest/gdscript-docs-maker:latest /game -o /output -d addons/grid
fdfind -E Grid.md | xargs rm

popd
