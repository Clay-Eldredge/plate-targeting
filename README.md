This is a code sample from a Roblox project

## Demo

https://github.com/user-attachments/assets/ab788895-80bb-43b3-b336-8f483ff4b935

## Summary

This code sample showcases the core grid architecture and dynamic targeting system for **Cards of Chaos**, a multiplayer last man standing game played on a destructible 9x9 board. Together, these modules bridge the underlying data structures with complex player inputs and workspace rendering.

### Core Systems Included:
* **Grid & State Management:** Object-oriented generation and health-tracking for the destructible tile board (`Grid.lua`, `Plate.lua`).
* **Pattern Math:** Data-driven matrix configurations and geometric rotation logic for evaluating spatial card effects (`Shapes.lua`, `ShapeMath.lua`).
* **Multi-Step Targeting:** A state machine and raycasting system that resolves sequential player interactions, such as dual-select or triple-select abilities (`TargetingData.lua`, `PlateTargeting.lua`, `GetTarget.lua`).
* **Dynamic Rendering:** Real-time visual projection of attack boundaries and directional indicators onto the board based on current hover context (`PlateHighlighting.lua`).
