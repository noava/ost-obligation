# Items

## Before adding an item

Before adding an item to the game you need to add a folder with the item name to the `/Items` folder. Add all the files for the items in here. Including the .blend file. Just follow file hierarchy that is used for other items. If there are alot of files for one type like Textures, you should create a folder. 

Then create a new scene from the .blend file. Then add the .tscn file to this folder. In this scene you can tweak some things needed for the item.

## Items in hands
To add an item to the game you need to add a folder with the item name to the `/Items` folder. In there you create the ItemData resource. By Create New -> Resource -> Search ItemData and then create. And call it the name of the item. In there it should show be fields to be filled out.

Name: The name of the item `string`

Description: The description of the item `string`

Stackable: If the item is stackable `true or false`

Texture: The texture of the item `Texture2D`. Shown in UI HUD

Item Type: The type of the item. None, Equipment, Material, Currency, Other `dropdown`

Item Scene: The 3d scene of the item `PackedScene`. A .tscn file of the model after creating seperate scene from .blend file. This scene is used for adding items to the inventory.

Item Offset: The offset of the item in the 3d scene `Vector3`. The position of the item in the hand.

Collision Height: The height of the item in the 3d scene `float`. For picking up items with raycast.

## Seeing the item in the game
You can test the item by adding it to `player_inv.tres` and add a SlotData with the ItemData resource and add quantity.

You can also add this resource to a `collectable.tscn` to pickup items in the game.