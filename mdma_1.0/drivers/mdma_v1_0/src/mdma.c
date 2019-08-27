/**
 * @file mdma.c
 * @brief MDMA Controller
 * @author matyunin.d
 * @date 23.08.2019
 * @copyright MIT License
 */

#include "mdma.h"
#include "xil_io.h"

/* Register Address */
#define REG_CR_OFFSET 		((u32)0x00)
#define REG_SR_OFFSET		((u32)0x04)
#define REG_IR_OFFSET		((u32)0x08)
#define REG_SA_OFFSET		((u32)0x0C)
#define REG_DA_OFFSET		((u32)0x10)
#define REG_SL_OFFSET		((u32)0x14)
#define REG_DL_OFFSET		((u32)0x18)

/* Register Map */
#define REG_CR_MM2S_MSK		((u32)0x00000001)
#define REG_CR_S2MM_MSK		((u32)0x00000002)
#define REG_CR_REST_MSK		((u32)0x00000004)

#define REG_SR_MM2S_DONE_MSK	((u32)0x00000001)
#define REG_SR_S2MM_DONE_MSK	((u32)0x00000002)
#define REG_SR_MM2S_ERROR_MSK	((u32)0x00000008)
#define REG_SR_S2MM_ERROR_MSK	((u32)0x00000010)


/* Register Operations */
#define WRITE_REG(base_addr, offset, data) 	Xil_Out32((base_addr) + (offset), (u32)(data))
#define READ_REG(base_addr, offset)			Xil_In32((base_addr) + (offset))

/**
 * @brief MDMA device initialization
 * @param dev Pointer to device
 * @param baseaddr Device base address
 * @return XST_SUCCESS | XST_FAILURE
 */
int mdma_init(mdma_dev_t *dev, u32 baseaddr)
{
	if (!dev || !baseaddr)
		return XST_FAILURE;

	dev->baseaddr = baseaddr;
	WRITE_REG(dev->baseaddr, REG_CR_OFFSET, 0);
	WRITE_REG(dev->baseaddr, REG_IR_OFFSET, 0);
	WRITE_REG(dev->baseaddr, REG_SA_OFFSET, 0);
	WRITE_REG(dev->baseaddr, REG_DA_OFFSET, 0);
	WRITE_REG(dev->baseaddr, REG_SL_OFFSET, 0);
	WRITE_REG(dev->baseaddr, REG_DL_OFFSET, 0);

	return XST_SUCCESS;
}

/**
 * @brief Reset MDMA device
 * @param dev Pointer to device
 * @return void
 */
void mdma_reset(mdma_dev_t *dev)
{
	WRITE_REG(dev->baseaddr, REG_CR_OFFSET, REG_CR_REST_MSK);
	for (int i = 0; i < 100; i++);
	WRITE_REG(dev->baseaddr, REG_CR_OFFSET, 0);
}

/**
 * @brief Get device status
 * @param Pointer to device
 * @return status
 */
u32 mdma_get_status(mdma_dev_t *dev)
{
	return READ_REG(dev->baseaddr, REG_SR_OFFSET);
}

/**
 * @brief Set interrupt mask
 * @param dev Pointer to device
 * @param irq_mask Interrupt mask
 * @return void
 */
void mdma_set_irq(mdma_dev_t *dev, u32 irq_mask)
{
	WRITE_REG(dev->baseaddr, REG_IR_OFFSET, irq_mask);
}

/**
 * @brief Start transaction
 * @param dev Pointer to device
 * @param dir Direction (MM2S or S2MM)
 * @param address Memory-mapped address
 * @param length Transaction length (in bytes)
 * @return void
 */
 void mdma_start(mdma_dev_t *dev, int dir, u32 address, u32 length)
{
	switch (dir) {
		case MDMA_DIR_MM2S:
			WRITE_REG(dev->baseaddr, REG_SA_OFFSET, address);
			WRITE_REG(dev->baseaddr, REG_SL_OFFSET, length);
			WRITE_REG(dev->baseaddr, REG_CR_OFFSET, REG_CR_MM2S_MSK);
			break;
		case MDMA_DIR_S2MM:
			WRITE_REG(dev->baseaddr, REG_DA_OFFSET, address);
			WRITE_REG(dev->baseaddr, REG_DL_OFFSET, length);
			WRITE_REG(dev->baseaddr, REG_CR_OFFSET, REG_CR_S2MM_MSK);
			break;
	}
}