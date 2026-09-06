class_name IntroBeat
extends Resource

## Texto que será digitado nesta cena
@export_multiline var text: String = ""

## Imagem exibida no ArtSprite (deixe vazio para manter a imagem atual)
@export var texture: Texture2D

enum MoveTarget { NONE, CAMERA, SPRITE }

## O que se move durante este beat: nada, a câmera ou o sprite de arte
@export var move_target: MoveTarget = MoveTarget.NONE

## Direção do movimento (ex: Vector2.DOWN, Vector2.RIGHT, Vector2(1, -0.3)...)
@export var direction: Vector2 = Vector2.ZERO

## Quantos pixels o nó (câmera ou sprite) vai se deslocar ao longo deste beat
@export var move_distance: float = 100.0

## Duração do fade "escuro -> claro" no início do beat, em segundos
@export var fade_in_duration: float = 1.5

## Duração do fade "claro -> escuro" no final do beat, em segundos
@export var fade_out_duration: float = 1.0

## Velocidade da digitação, em caracteres por segundo (0 = aparece tudo de uma vez)
@export var text_speed: float = 15.0

## Quanto tempo a cena fica parada, já com o texto completo, antes do fade out
@export var hold_time: float = 1.5
