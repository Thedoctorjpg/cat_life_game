# Cat Life Game

A Playdate game built with Lua that follows the "Nude Food" philosophy: eating fresh, minimally processed food from the land, sea, and sky.

## Game Mechanics
* **Hunting:** Catch fish from the sea (`fish.png`) and birds from the sky (`bird.png`).
* **Preparation:** Take your fresh ingredients to the development kitchen (the food bowl) to process them into a balanced meal.
* **Survival:** Monitor your **Hunger Meter**. If it hits zero, the game is over.
* **Natural Cycles:** After eating a healthy meal, the cat will naturally digest and leave a "surprise" (`poop.png`).
* **High Score:** See how many fish you can catch and how many days you can survive.

## Folder Structure
* `/src`: Contains the source code.
* `/src/images`: Pixel art assets including the cat, statue, and food.
* `/src/sounds`: Sound effects like `splash.mp3`, `smash.mp3`, and `crow-call.mp3`.
* `/builds`: Destination for the compiled `.pdx` file.

## How to Compile
Ensure you have the Playdate SDK installed, then run the following command in your terminal:
`pdc src builds/cat_life_game.pdx`

## Credits
* **Concept:** Inspired by Nadia Lim’s "Nude Food" philosophy—real food straight from nature.
* **Programming:** Developed in Lua for the Playdate handheld console.
