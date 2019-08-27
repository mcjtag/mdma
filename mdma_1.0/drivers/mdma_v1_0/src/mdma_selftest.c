/**
 * @file mdma_selftest.c
 * @brief Selftest
 * @author matyunin.d
 * @date 23.08.2019
 * @copyright MIT License
 */

#include "mdma.h"
#include "xparameters.h"
#include "stdio.h"
#include "xil_io.h"

/**
 * @brief Selftest
 * @param baseaddr_p Base address
 * @return XST_SUCCESS
 */
int mdma_selftest(void *baseaddr_p)
{
	(void)baseaddr_p;

	return XST_SUCCESS;
}
