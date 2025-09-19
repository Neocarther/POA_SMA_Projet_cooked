# POA_SMA_Projet_cooked

A simplified version of the Overcooked game made in Godot 4.2.

## Game Description

This is a fast-paced cooking game where you play as a chef trying to fulfill customer orders within a time limit. Navigate around a kitchen, collect ingredients, prepare them at different stations, and serve completed dishes to earn points.

## How to Play

### Controls
- **WASD** or **Arrow Keys**: Move the player
- **E** or **Space**: Interact with stations and objects
- **W (Hold)**: When at a counter, take items instead of placing them

### Game Mechanics

1. **Ingredients**: Pick up tomatoes and lettuce from ingredient stations
2. **Preparation**: 
   - Use cutting stations to chop ingredients (tomato → tomato_cut, lettuce → lettuce_cut)
   - Use cooking stations to cook tomatoes (tomato → tomato_cooked)
3. **Storage**: Use counters to temporarily store ingredients
4. **Orders**: Check the orders panel to see what dishes customers want
5. **Serving**: Take completed dishes to the serving station to fulfill orders

### Recipes
- **Tomato Salad**: tomato_cut + lettuce_cut
- **Cooked Tomato**: tomato_cooked
- **Simple Salad**: lettuce_cut + lettuce_cut
- **Mixed Salad**: tomato_cut + lettuce_cut + lettuce_cut

### Scoring
- Complete orders before they expire to earn 100 points each
- Game lasts 2 minutes
- Try to score as many points as possible!

## Station Types

- **Red Stations**: Tomato ingredient source
- **Green Stations**: Lettuce ingredient source
- **Gray Stations**: Cutting boards for chopping ingredients
- **Dark Red Stations**: Cooking stations for heating ingredients
- **Green Serving Station**: Where you deliver completed orders
- **Brown Counters**: Temporary storage for ingredients

## Running the Game

1. Open the project in Godot 4.2 or later
2. Press F5 or click the play button
3. Select `res://scenes/Main.tscn` as the main scene when prompted

Enjoy cooking!