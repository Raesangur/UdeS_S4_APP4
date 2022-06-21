#include <stdio.h>
#include <string.h>
#define N 4  /* nombre d'etats du code */


// Pour le devoir: Conserver la distinction entre les 2 fonctions!

// Somme/comparaison/selection (add/compare/select)
// Parametres: metriques, survivants en entree, survivants en sortie
void acs(unsigned int* met, int* sinput, int* soutput)
{
	unsigned int temp, j;
	for(j=0; j< N; j++)
	{
        temp = met[j]+sinput[j];
        if (*soutput <= temp)
        {
            printf("Skip\n");
        }
        if (temp < *soutput)
        {
            *soutput = temp;
            printf("Hit! :");
        }
		printf("%d\n", *soutput);
	}
}

// Calcul des survivant, 
void CalculSurvivants(unsigned int* met, int* sinput, int* soutput)
{
	unsigned int i;  
	for (i=0; i< N; i++) {
		soutput[i]=250;
		acs(&met[i*N], sinput, &soutput[i]);
	}
}

// Point d'entree du programme
int main()
{
	// variables a passer a ACS. Peuvent etres placees directement 
	// en memoire dans l'assembleur
    int si[N] = {0};
    int so[N] = {0};
    unsigned int metriques[N][N] = {4, 3, 3, 2,   0, 3, 5, 4,   4, 3, 3, 2,   2, 5, 3, 2};
	
	// Execution - pour chaque code du message
    CalculSurvivants( &metriques[0][0], &si[0], &so[0] );
    
    printf("si: %d, %d, %d, %d\n", si[0], si[1], si[2], si[3]);
    printf("so: %d, %d, %d, %d\n", so[0], so[1], so[2], so[3]);
			
    return 0;
}
