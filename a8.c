/*
 * 20060428 - Version inicial.
 */

void get_digit(int a);

char* digit[10] = {
	"cero", "uno", "dos", "tres", "cuatro",
	"cinco", "seis", "siete", "ocho", "nueve"
};

int main(void)
{
	int a;

	printf("Ingrese entero positivo: ");
	scanf("%d", &a);

	if (a < 0) {
		printf("Error: el entero es negativo\n");
	}
	else {
		get_digit(a);
		printf("\n");
	}

	return 0;
}

void get_digit(int a)
{
	int r;
	
	r = a % 10;
	a /= 10;

	if (a > 0) get_digit(a);

	printf("%s ", digit[r]);
	return;
}
