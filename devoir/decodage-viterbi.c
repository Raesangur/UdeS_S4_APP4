#include <stdio.h>
#include <string.h>
#define L 12  /* longueur du message en bits */
#define N 4  /* nombre d'etats du code */

// Message de test pre-encode
static const unsigned int bitsrc[L] = { 5, 6, 2, 3, 1, 7, 0, 5, 3, 1, 2, 6 };

// Metriques pour le treilli serre.  
// Voir section 3.2 de l'Annexe sur Viterbi pour explications.
//
//
// 1ere matrice de metriques pour le treilli serre
static const unsigned int pr1[N][N] = {
        {0,7,6,1},
        {5,2,3,4},
        {0,7,6,1},
        {5,2,3,4}
    };
// 2e matrice de metriques pour le treilli serre
static const unsigned int pr2[N][N] = {
        {0,0,7,7},
        {6,6,1,1},
        {5,5,2,2},
        {3,3,4,4}
    };

// Exemple (lie a la figure 1.2 de l'annexe Viterbi).
// Soit une transition 0x0 --> 0x2 --> 0x3 dans le treilli regulier.
// La figure 1.2 de l'Annexe A montre que les codes de transitions sont 0x5 et 0x3
// Dans le treilli serre, la transition 0x0 --> 0x3 est equivalente, et
// s'attend aux memes codes, que l'on retrouve dans pr1 et pr2:
// pr1[0][3] = 5;
// pr2[0][3] = 3;


// compte le nombre de bits Ã  '1' sur les 4 bits les moins significatifs
unsigned int popcount4( unsigned int a)
{
  return( (a >> 3 & 1) + (a >> 2 & 1) + (a >> 1 & 1) + (a & 1));
}

// Calcul la metrique pour un treilli serre
void genmetrique(unsigned int br1, unsigned int br2, unsigned int *m)
{
    unsigned int i, j;
    
    for (i=0; i < N; i++) {
        for (j=0; j < N; j++) {
			m[i*N+j] =   popcount4(br1 ^ pr1[i][j]) 
					   + popcount4(br2 ^ pr2[i][j]);
		}
    }
}

// Pour le devoir: Conserver la distinction entre les 2 fonctions!

// Somme/comparaison/selection (add/compare/select)
// Parametres: metriques, survivants en entree, survivants en sortie
void acs(unsigned int* met, int* sinput, int* soutput)
{
	unsigned int temp, j;
	for(j=0; j< N; j++) {
			temp = met[j]+sinput[j];
			*soutput = temp < *soutput ? temp : *soutput;
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
    int si[N], so[N];
    unsigned int metriques[N][N];
	
	// variable locale
	int i;
    
	// Initialisation
    for (i=0; i<N; i++) {
		si[i] = 0;
    }
	
	// Execution - pour chaque code du message
    for (i=0; i < L; i++) {
		// Treilli serre, donc a tous les deux codes
		if (i%2 != 0) {
			genmetrique( bitsrc[i-1], bitsrc[i], &metriques[0][0] );
			CalculSurvivants( &metriques[0][0], &si[0], &so[0] );
			
			// Copie pour le prochain cycle
			memcpy(si, so, sizeof(si));
		}
	}
    for (i=0; i < N; i++) {
		printf( "%d ", so[i] ); 
	}
    printf("\n");
    return 0;
}
