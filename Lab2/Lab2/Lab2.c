/*
This code will cause a TekBot connected to the AVR board to
move forward and when it touches an obstacle, it will reverse
and turn away from the obstacle and resume forward motion.

PORT MAP
Port B, Pin 4 -> Output -> Right Motor Enable
Port B, Pin 5 -> Output -> Right Motor Direction
Port B, Pin 7 -> Output -> Left Motor Enable
Port B, Pin 6 -> Output -> Left Motor Direction
Port D, Pin 1 -> Input -> Left Whisker
Port D, Pin 0 -> Input -> Right Whisker
*/

#define F_CPU 16000000
#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>

int main(void)
{
	DDRB = 0b11110000;
	PORTB = 0b11110000;
	DDRD = 0b00000000;
	PORTD = 0b11111111;
	/*Poll a value from port*/
	unsigned int value;	
	/*Make TekBot move forward*/
	PORTB = 0b01100000;
	_delay_ms(500);
	/*Loop forever*/
	for( ; ; )
	{		
		/*Poll TekBot whisker for input*/
		value = PIND;
		/*If right whisker is hit*/
		if(value == 0b11111110)
		{
			/*Reverse TekBot*/
			PORTB = 0b00000000;
			_delay_ms(1000);
			/*Make TekBot turn left*/
			PORTB = 0b00100000;
			_delay_ms(1000);
			/*Make TekBot move forward*/
			PORTB = 0b01100000;
			_delay_ms(500);
		}
		/*If left whisker is hit*/
		if(value == 0b11111101)
		{
			/*Reverse TekBot*/
			PORTB = 0b00000000;
			_delay_ms(1000);
			/*Make TekBot turn right*/
			PORTB = 0b01000000;
			_delay_ms(1000);
			/*Make TekBot move forward*/
			PORTB = 0b01100000;
			_delay_ms(500);
		}
	};
}