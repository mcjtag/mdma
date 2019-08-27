/**
 * @file mdma.h
 * @brief MDMA Controller
 * @author matyunin.d
 * @date 23.08.2019
 * @copyright MIT License
 */

#ifndef MDMA_H
#define MDMA_H

#include "xil_types.h"
#include "xstatus.h"

enum MDMA_FLAG {
	MDMA_FLAG_MM2S_DONE = 1,
	MDMA_FLAG_S2MM_DONE = 2,
	MDMA_FLAG_MM2S_ERROR = 8,
	MDMA_FLAG_S2MM_ERROR = 16,
	MDMA_FLAG_ALL = 27
};

enum MDMA_DIR {
	MDMA_DIR_MM2S = 0,
	MDMA_DIR_S2MM = 1
};

typedef struct{
	u32 baseaddr;
} mdma_dev_t;


int mdma_init(mdma_dev_t *dev, u32 baseaddr);
void mdma_reset(mdma_dev_t *dev);
u32 mdma_get_status(mdma_dev_t *dev);
void mdma_set_irq(mdma_dev_t *dev, u32 irq_mask);
void mdma_start(mdma_dev_t *dev, int dir, u32 address, u32 length);

int mdma_selftest(void *baseaddr_p);

#endif // MDMA_H
