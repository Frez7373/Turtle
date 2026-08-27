# Turtle

## Programs

- `house.lua` - American suburban house builder.
- `office.lua` - Two-floor American-style office builder.
- `supply.lua` - Automatic material restocking system used by both builders.

## Automatic restocking

The turtle keeps one starter item of each required material in its building slots.
When the selected material reaches 1 item, the next placement automatically triggers a supply trip.

The turtle returns to the exact position and orientation where construction started, scans the connected storage inventory for the required item, fills the turtle slot, and replays its recorded route back to the construction position.

The storage chest does not use fixed slots. Materials can be placed anywhere in the chest and the supply system searches the whole inventory by item name and NBT hash.

## Hardware setup

The turtle and the storage chest must be connected to the same wired modem network.

1. Put a wired modem on the turtle.
2. Put a wired modem on the storage chest.
3. Connect them with networking cable.
4. Put materials in any chest slots.
5. Before starting, put at least 1 item of every material used by the selected builder into the corresponding turtle slots.
6. Start the builder from the construction start position.

The chest can contain many stacks of each material. It does not need to reserve a specific slot for each block type.

## Turtle slots

### House

1. Wall blocks
2. Glass
3. Door
4. Roof blocks
5. Foundation
6. Floor blocks
7. Stairs
8. Lights
9. Interior wall blocks

### Office

1. Wall blocks
2. Glass
3. Doors
4. Roof blocks
5. Foundation
6. Floor blocks
7. Stairs
8. Lights
9. Interior wall blocks
10. Trim blocks
